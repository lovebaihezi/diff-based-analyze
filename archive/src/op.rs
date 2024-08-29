use polars::frame::DataFrame;

#[derive(serde::Deserialize, serde::Serialize, Default)]
pub struct ChartData {
    pub repo: String,
    pub ids: Vec<String>,
    pub counts: Vec<usize>,
}

#[derive(serde::Deserialize, serde::Serialize, Default)]
pub enum AppOp {
    #[default]
    Noop,
    Init,
    UserQuit,
    OpeningFile(String),
    LoadingFile(String),
    AnalyzingFile(String),
    LoadedFile(Box<DataFrame>),
    UpdateDF(Box<DataFrame>),
    FilterCWEDone(usize),
    PivitDone(Box<DataFrame>),
    AddCWEChartData(ChartData),
    Done(String),
    #[serde(skip)]
    EncounterError(anyhow::Error),
}
