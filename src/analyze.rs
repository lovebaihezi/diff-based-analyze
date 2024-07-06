use std::{fs::File, path::Path};

use flume::{Receiver, Sender};
use pivot::pivot;
use polars::{lazy::dsl::col, prelude::*};

use crate::{op::ChartData, AppOp};

pub struct Analyze {
    analyze_file: String,
    sender: Sender<AppOp>,
    receiver: Receiver<AppOp>,
}

impl Analyze {
    pub fn new(path: String, sender: Sender<AppOp>, receiver: Receiver<AppOp>) -> Self {
        Self {
            sender,
            receiver,
            analyze_file: path,
        }
    }

    fn init_df(&self, file: File) -> anyhow::Result<DataFrame> {
        let fields = [
            Field::new("cweID", DataType::String),
            Field::new("fileName", DataType::String),
            Field::new("codeWithIssue", DataType::String),
            Field::new("time", DataType::String),
            Field::new("content", DataType::String),
            Field::new("msg", DataType::String),
            Field::new("path", DataType::String),
            Field::new("level", DataType::Int64),
            Field::new("time", DataType::Int64),
            Field::new("hostname", DataType::String),
            Field::new("pir", DataType::Int64),
        ];
        let schema = Schema::from_iter(fields.into_iter());
        let df: DataFrame = JsonLineReader::new(file)
            .with_schema(Arc::new(schema))
            .finish()?;
        let df = df
            .lazy()
            .filter(col("cweID").is_not_null())
            .with_column(
                col("cweID")
                    .str()
                    .extract(lit(r"(CWE-\d+)"), 1)
                    .alias("cwe_id"),
            )
            .with_column(
                col("fileName")
                    .str()
                    .extract(lit(r"micros/([^/]+)/"), 1)
                    .alias("repo"),
            )
            .collect()?
            .select(["cweID", "cwe_id", "repo", "fileName", "codeWithIssue"])?;
        self.sender
            .send(AppOp::LoadedFile(Box::new(df.clone().select([
                "cwe_id",
                "repo",
                "fileName",
                "codeWithIssue",
            ])?)))?;
        self.sender
            .send(AppOp::AnalyzingFile(self.analyze_file.clone()))?;
        Ok(df)
    }

    pub fn filter_cwe(&self, df: DataFrame) -> anyhow::Result<DataFrame> {
        let df = df
            .lazy()
            .filter(col("cweID").str().contains(lit("CWE-\\d+"), false))
            .select([
                col("cwe_id"),
                col("repo"),
                col("fileName"),
                col("codeWithIssue"),
            ])
            .collect()?;
        self.sender.send(AppOp::FilterCWEDone(df.height()))?;
        Ok(df)
    }

    pub fn pivit_df(&self, df: DataFrame) -> anyhow::Result<DataFrame> {
        let df = df
            .lazy()
            .group_by(["repo"])
            .agg([col("cwe_id")
                .value_counts(true, false, "cwe_id_occur".to_owned(), false)
                .alias("cwe_id_occur")])
            .explode(["cwe_id_occur"])
            .unnest(["cwe_id_occur"])
            .collect()?;
        let pivot_df = pivot(
            &df,
            ["repo"],
            Some(["cwe_id"]),
            Some(["cwe_id_occur"]),
            true,
            None,
            None,
        )?
        .fill_null(FillNullStrategy::Zero)?;
        self.sender
            .send(AppOp::PivitDone(Box::new(pivot_df.clone())))?;
        Ok(pivot_df)
    }

    pub fn init(self) -> anyhow::Result<()> {
        let path: &Path = Path::new(&self.analyze_file);
        self.sender
            .send(AppOp::OpeningFile(self.analyze_file.clone()))?;
        let file = File::open(path)?;
        self.sender
            .send(AppOp::LoadingFile(self.analyze_file.clone()))?;
        let df = self.init_df(file)?;
        let df = self.filter_cwe(df)?;
        let df = self.pivit_df(df)?;
        let cwe_ids: Vec<String> = df
            .column("cwe_id")?
            .str()?
            .into_iter()
            .flatten()
            .map(|s| s.to_owned())
            .collect();
        for column in df.get_columns() {
            if column.name() == "cwe_id" {
                continue;
            }
            let counts: Vec<usize> = column
                .u32()?
                .into_iter()
                .flatten()
                .map(|v| v as usize)
                .collect();
            self.sender.send(AppOp::AddCWEChartData(ChartData {
                repo: column.name().to_owned(),
                ids: cwe_ids.clone(),
                counts,
            }))?;
        }
        self.sender.send(AppOp::Done(self.analyze_file.clone()))?;
        Ok(())
    }
}
