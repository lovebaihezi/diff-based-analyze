#![warn(clippy::all, rust_2018_idioms)]

#[global_allocator]
static ALLOC: mimalloc::MiMalloc = mimalloc::MiMalloc;

mod app;
pub use app::TemplateApp;
