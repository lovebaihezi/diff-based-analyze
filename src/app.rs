use crate::{
    op::{AppOp, ChartData},
    state::{AppPage, AppState},
    Analyze,
};
use egui::{Align, CentralPanel, FontData, FontDefinitions, Id, Layout};
use egui_extras::{Column, TableBuilder};
use egui_plot::{Bar, BarChart, Legend, Plot};
use flume::{Receiver, Sender};
use polars::{datatypes::AnyValue, frame::DataFrame};
use std::{borrow::Borrow, time::Duration};

/// We derive Deserialize/Serialize so we can persist app state on shutdown.
#[derive(serde::Deserialize, serde::Serialize)]
#[serde(default)] // if we add new fields, give them default values when deserializing old state
pub struct AnalyzeApp {
    state: AppState,
    op: AppOp,
    current_row: usize,
    chart_data: Vec<ChartData>,
    #[serde(skip)]
    pivit_table: Option<Box<DataFrame>>,

    #[serde(skip)]
    cwe_counts: usize,

    #[serde(skip)]
    analyze_thread: std::thread::JoinHandle<()>,

    #[serde(skip)]
    sender: Sender<AppOp>,

    #[serde(skip)]
    receiver: Receiver<AppOp>,
}

impl AnalyzeApp {
    pub fn update_op(&mut self, op: AppOp) {
        match op {
            AppOp::LoadedFile(df) => self.state.update_df(df),
            AppOp::FilterCWEDone(size) => self.cwe_counts = size,
            AppOp::PivitDone(df) => self.pivit_table = Some(df),
            AppOp::AddCWEChartData(data) => self.chart_data.push(data),
            _ => {
                self.op = op;
            }
        }
    }

    pub fn should_update(&mut self) -> bool {
        !self.receiver.is_empty()
    }
}

impl Default for AnalyzeApp {
    fn default() -> Self {
        let (rx, rt) = flume::unbounded::<AppOp>();
        let sender = rx.clone();
        let recv = rt.clone();
        let thread = std::thread::spawn(move || {
            let err_sender = sender.clone();
            if let Err(e) = Analyze::new("./micros.3.log".to_string(), sender, recv).init() {
                tracing::error!("{:?}", e);
                err_sender.send(AppOp::EncounterError(e)).unwrap()
            };
        });
        rx.send(AppOp::Init).unwrap();
        Self {
            state: Default::default(),
            op: Default::default(),
            chart_data: Default::default(),
            pivit_table: None,
            cwe_counts: 0,
            analyze_thread: thread,
            current_row: 0,
            sender: rx,
            receiver: rt,
        }
    }
}

impl AnalyzeApp {
    /// Called once before the first frame.
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let mut definition = FontDefinitions::default();
        let fira_code_bytes = include_bytes!("../FiraCode-VariableFont_wght.ttf");
        let fira_code_font_data = FontData::from_static(fira_code_bytes);
        definition
            .font_data
            .insert("fira_code".to_owned(), fira_code_font_data);
        definition
            .families
            .get_mut(&egui::FontFamily::Monospace)
            .unwrap()
            .insert(0, "fira_code".to_owned());
        definition
            .families
            .get_mut(&egui::FontFamily::Proportional)
            .unwrap()
            .insert(0, "fira_code".to_owned());
        cc.egui_ctx.set_fonts(definition);

        // Load previous app state (if any).
        // Note that you must enable the `persistence` feature for this to work.
        if let Some(storage) = cc.storage {
            return eframe::get_value(storage, eframe::APP_KEY).unwrap_or_default();
        }

        Default::default()
    }

    fn show_code(language: &str, code: &str, ui: &mut egui::Ui) {
        let theme = egui_extras::syntax_highlighting::CodeTheme::from_memory(ui.ctx());
        egui_extras::syntax_highlighting::code_view_ui(ui, &theme, code, language);
    }

    fn table(&mut self, ui: &mut egui::Ui) {
        if let Some(df) = self.state.read_df() {
            let nr_cols = df.width();
            let nr_rows = df.height();
            let cols = &df.get_column_names();

            TableBuilder::new(ui)
                .columns(Column::auto(), nr_cols)
                .resizable(true)
                .striped(true)
                .header(5.0, |mut header| {
                    for head in cols {
                        header.col(|ui| {
                            ui.heading(head.to_string());
                        });
                    }
                })
                .body(|body| {
                    body.rows(10.0, nr_rows, |mut row| {
                        let index = row.index();
                        for col in cols {
                            row.col(|ui| {
                                if let Ok(column) = &df.column(col) {
                                    if let Ok(value) = column.get(index) {
                                        match (*col, value) {
                                            ("codeWithIssue", AnyValue::String(str)) => {
                                                Self::show_code(
                                                    "c++",
                                                    str.trim_start_matches("<codesContainsIssue>")
                                                        .trim_start_matches("```cpp")
                                                        .trim_matches('`')
                                                        .trim_matches('\n'),
                                                    ui,
                                                );
                                            }
                                            (_, v) => {
                                                ui.label(
                                                    format!("{}", v).trim_start_matches("<CWE-ID>"),
                                                );
                                            }
                                        }
                                    }
                                }
                            });
                        }
                    });
                });
        }
    }

    fn pivit_table(&mut self, ui: &mut egui::Ui) {
        if let Some(df) = &self.pivit_table {
            let nr_cols = df.width();
            let nr_rows = df.height();
            let cols = &df.get_column_names();

            TableBuilder::new(ui)
                .columns(Column::auto(), nr_cols)
                .resizable(true)
                .striped(true)
                .header(5.0, |mut header| {
                    for head in cols {
                        header.col(|ui| {
                            ui.heading(head.to_string());
                        });
                    }
                })
                .body(|body| {
                    body.rows(10.0, nr_rows, |mut row| {
                        let index = row.index();
                        for col in cols {
                            row.col(|ui| {
                                if let Ok(column) = &df.column(col) {
                                    if let Ok(value) = column.get(index) {
                                        ui.label(format!("{}", value));
                                    }
                                }
                            });
                        }
                    });
                });
        }
    }

    fn code_with_issue(&mut self, ui: &mut egui::Ui) {
        let code_with_issue = self.state.current("codeWithIssue", self.current_row);
        match code_with_issue {
            Ok(Some(code)) => {
                Self::show_code(
                    "c++",
                    code.trim_start_matches("<codesContainsIssue>")
                        .trim_start_matches("```cpp")
                        .trim_matches('`')
                        .trim_matches('\n'),
                    ui,
                );
                ui.end_row();
            }
            _ => {}
        };
    }

    fn show_cwe(&mut self, ui: &mut egui::Ui) {
        let cwe_id_des = self.state.current("cweID", self.current_row);
        match cwe_id_des {
            Ok(Some(cwe)) => {
                ui.label(format!("{}", cwe).trim_start_matches("<CWE-ID>"));
            }
            _ => {}
        }
    }

    fn visual(&mut self, ui: &mut egui::Ui) {
        let file_name = self.state.current("fileName", self.current_row);
        ui.horizontal_top(|ui| {
            ui.with_layout(Layout::top_down(Align::Center), |ui| {
                ui.horizontal(|ui| {
                    // First button aligned to the left
                    ui.with_layout(Layout::left_to_right(Align::Min), |ui| {
                        if ui.button("prev").clicked() && self.current_row > 0 {
                            self.current_row -= 1;
                        }
                    });
                    // Spacer to push the text to the center
                    if let Ok(Some(str)) = file_name {
                        ui.label(str);
                    }
                    ui.add_space(ui.available_width() / 2.0 - ui.spacing().item_spacing.x);
                    // Second button aligned to the right
                    ui.with_layout(Layout::right_to_left(Align::Min), |ui| {
                        if ui.button("next").clicked() && self.current_row < self.state.df_height()
                        {
                            self.current_row += 1;
                        }
                    });
                });
            });
        });
        ui.separator();
        if let Ok(Some(_)) = file_name {
            ui.vertical(|ui| {
                // Show Code
                self.code_with_issue(ui);
                ui.end_row();
                // Show CWE ID and des
                self.show_cwe(ui);
            });
        } else {
            ui.vertical_centered(|ui| ui.horizontal_centered(|ui| ui.label("No data loaded.")));
        }
    }

    fn diagnostics(&mut self, ui: &mut egui::Ui) {
        ui.vertical_centered(|ui| {
            ui.with_layout(egui::Layout::bottom_up(egui::Align::LEFT), |ui| {
                egui::warn_if_debug_build(ui);
            });

            ui.with_layout(
                egui::Layout::bottom_up(egui::Align::RIGHT),
                |ui| match self.op.borrow() {
                    AppOp::Noop => ui.label("Noop"),
                    AppOp::Init => ui.label("Init App"),
                    AppOp::UserQuit => ui.label("User Quit"),
                    AppOp::OpeningFile(file) => ui.label(format!("Opening {}", file)),
                    AppOp::LoadingFile(file) => {
                        ui.label(format!("Polars JSON Reader Loading {}", file))
                    }
                    AppOp::LoadedFile(_) => ui.label("Loaded File"),
                    AppOp::AnalyzingFile(file) => ui.label(format!("Analyzing {}", file)),
                    AppOp::FilterCWEDone(_) => ui.label("Filter CWE Done"),
                    AppOp::AddCWEChartData(_) => ui.label("Add CWE Chart Data"),
                    AppOp::UpdateDF(_) => ui.label("Update DF"),
                    AppOp::PivitDone(_) => ui.label("Pivit Done"),
                    AppOp::Done(file) => ui.label(format!("Done {}", file)),
                    AppOp::EncounterError(e) => ui.code(e.to_string()),
                },
            )
        });
    }

    fn main(&mut self, ui: &mut egui::Ui) {
        ui.horizontal(|ui| ui.horizontal_centered(|ui| ui.heading("Main")));
    }

    fn overall_cwes(&mut self, ui: &mut egui::Ui) {
        ui.vertical_centered(|ui| {
            if let Some(df) = self.state.read_df() {
                let files = df.height();
                let cwes = self.cwe_counts;
                ui.label(format!("Overall cwes: {} / {}", cwes, files));
            } else {
                ui.spinner();
            }
        });
        ui.end_row();
        ui.separator();

        let mut charts: Vec<BarChart> = vec![];
        for (i, chart_data) in self.chart_data.iter().enumerate() {
            let mut bars: Vec<Bar> = vec![];
            for (i, (id, count)) in chart_data
                .ids
                .iter()
                .zip(chart_data.counts.iter())
                .enumerate()
            {
                bars.push(Bar::new(i as f64, *count as f64).name(id).width(0.7));
            }
            let arr: Vec<&BarChart> = charts.iter().take(i).collect();
            let chart = BarChart::new(bars)
                .name(format!("CWE in Repo {}", chart_data.repo))
                .stack_on(arr.as_slice());
            charts.push(chart);
        }

        Plot::new("CWE under Each Repo")
            .legend(Legend::default())
            .x_axis_label("repo")
            .data_aspect(1.0)
            .allow_drag(true)
            .show(ui, |plot_ui| {
                for chart in charts {
                    plot_ui.bar_chart(chart);
                }
            })
            .response;
    }

    fn plots(&mut self, ui: &mut egui::Ui) {
        self.overall_cwes(ui);
    }

    pub fn ui(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::TopBottomPanel::top(Id::new("top"))
            .max_height(24.)
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    ui.heading("Analyze APP");
                    for enum_value in [
                        AppPage::Main,
                        AppPage::Detailed,
                        AppPage::Plots,
                        AppPage::Table,
                        AppPage::PivitTable,
                    ] {
                        if ui
                            .selectable_label(
                                self.state.page() == enum_value,
                                format!("{}", enum_value),
                            )
                            .clicked()
                        {
                            self.state.set_page(enum_value);
                        }
                    }
                })
            });
        CentralPanel::default().show(ctx, |ui| match self.state.page() {
            AppPage::Main => self.main(ui),
            AppPage::Detailed => self.visual(ui),
            AppPage::Table => self.table(ui),
            AppPage::Plots => self.plots(ui),
            AppPage::PivitTable => self.pivit_table(ui),
        });
        egui::TopBottomPanel::bottom(Id::new("btm"))
            .max_height(20.)
            .show(ctx, |ui| ui.horizontal_centered(|ui| self.diagnostics(ui)));
    }
}

impl eframe::App for AnalyzeApp {
    /// Called by the frame work to save state before shutdown.
    fn save(&mut self, storage: &mut dyn eframe::Storage) {
        eframe::set_value(storage, eframe::APP_KEY, self);
    }

    /// Called each time the UI needs repainting, which may be many times per second.
    fn update(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {
        egui_extras::install_image_loaders(ctx);
        if let Ok(op) = self.receiver.try_recv() {
            self.update_op(op);
        }
        self.ui(ctx, frame);
        if self.should_update() {
            ctx.request_repaint_after(Duration::from_millis(1000 / 144));
        }
    }
}
