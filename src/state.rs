use std::fmt::Display;

use polars::{datatypes::AnyValue, error::PolarsResult, frame::DataFrame};

#[derive(serde::Deserialize, serde::Serialize, Default)]
#[serde(default)] // if we add new fields, give them default values when deserializing old state
pub struct AppState {
    df: Option<Box<DataFrame>>,
    df_updated: bool,
    file_path: String,
    app_page: AppPage,
}

#[derive(serde::Deserialize, serde::Serialize, Debug, Clone, Copy, PartialEq, Eq)]
pub enum AppPage {
    Main,
    Table,
    Detailed,
    Plots,
    PivitTable,
}

impl Display for AppPage {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AppPage::Main => write!(f, "Main"),
            AppPage::Table => write!(f, "Table"),
            AppPage::Detailed => write!(f, "Detailed"),
            AppPage::Plots => write!(f, "Plots"),
            AppPage::PivitTable => write!(f, "PivitTable"),
        }
    }
}

impl Default for AppPage {
    fn default() -> Self {
        AppPage::Main
    }
}

impl AppState {
    pub fn new() -> Self {
        Default::default()
    }

    pub fn page(&self) -> AppPage {
        self.app_page
    }

    pub fn set_page(&mut self, page: AppPage) {
        self.app_page = page;
    }

    pub fn file_path(&self) -> &String {
        &self.file_path
    }

    pub fn mut_file_path(&mut self) -> &mut String {
        &mut self.file_path
    }

    pub fn update_df(&mut self, df: Box<DataFrame>) {
        self.df_updated = true;
        self.df = Some(df);
    }

    pub fn is_df_updated(&self) -> bool {
        self.df_updated
    }

    pub fn read_df(&mut self) -> Option<&DataFrame> {
        self.df_updated = false;
        match self.df {
            Some(ref df) => Some(df.as_ref()),
            None => None,
        }
    }

    pub fn df_height(&self) -> usize {
        match self.df {
            Some(ref df) => df.height(),
            None => 0,
        }
    }

    pub fn current(&self, name: &str, index: usize) -> PolarsResult<Option<&str>> {
        match self.df {
            Some(ref df) => {
                let column = df.column(name)?;
                let row = column.get(index)?;
                match row {
                    AnyValue::String(str) => Ok(Some(str)),
                    _ => Ok(None),
                }
            }
            None => Ok(None),
        }
    }
}
