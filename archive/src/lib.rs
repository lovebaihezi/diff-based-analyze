#![warn(clippy::all, rust_2018_idioms)]

#[cfg(not(target_arch = "wasm32"))]
#[global_allocator]
static ALLOC: mimalloc::MiMalloc = mimalloc::MiMalloc;

mod analyze;
mod app;
mod op;
mod state;
pub use analyze::Analyze;
pub use app::AnalyzeApp;
pub use op::AppOp;
pub use state::AppState;
