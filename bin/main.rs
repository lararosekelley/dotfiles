mod cli;
mod commands;
mod fs;
mod model;
mod ui;

use anyhow::Result;
use clap::Parser;

fn main() -> Result<()> {
    let cli = cli::Cli::parse();
    commands::run(cli)
}
