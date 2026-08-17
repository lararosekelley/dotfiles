use clap::{Args, Parser, Subcommand, ValueEnum};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(
    name = "dotfiles",
    version,
    about = "Sync dotfiles between repo and home"
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    Sync(SyncArgs),
    Status(StatusOptions),
}

#[derive(Args, Debug)]
pub struct SyncArgs {
    #[command(subcommand)]
    pub command: SyncCommand,
}

#[derive(Subcommand, Debug)]
pub enum SyncCommand {
    ToHome(SyncOptions),
    ToRepo(SyncOptions),
}

#[derive(Args, Debug, Clone)]
pub struct SyncOptions {
    #[arg(long)]
    pub root: Option<PathBuf>,

    #[arg(long)]
    pub home: Option<PathBuf>,

    #[arg(long, action = clap::ArgAction::Append)]
    pub only: Vec<String>,

    #[arg(long, action = clap::ArgAction::Append)]
    pub exclude: Vec<String>,

    #[arg(long)]
    pub yes: bool,

    #[arg(long)]
    pub dry_run: bool,

    #[arg(long)]
    pub symlink: bool,

    #[arg(long)]
    pub backup: bool,
}

#[derive(Args, Debug, Clone)]
pub struct StatusOptions {
    #[arg(long)]
    pub root: Option<PathBuf>,

    #[arg(long)]
    pub home: Option<PathBuf>,

    #[arg(long, action = clap::ArgAction::Append)]
    pub only: Vec<String>,

    #[arg(long, action = clap::ArgAction::Append)]
    pub exclude: Vec<String>,

    #[arg(long, value_enum, default_value = "to-home")]
    pub direction: DirectionArg,

    #[arg(long)]
    pub symlink: bool,

    /// Show a unified diff of the contents that would change
    #[arg(long)]
    pub diff: bool,

    /// Colourise diff output
    #[arg(long, value_enum, default_value = "auto")]
    pub color: ColorArg,
}

#[derive(ValueEnum, Debug, Clone, Copy)]
pub enum DirectionArg {
    ToHome,
    ToRepo,
}

#[derive(ValueEnum, Debug, Clone, Copy)]
pub enum ColorArg {
    /// Colour when stdout is a terminal and NO_COLOR is unset
    Auto,
    Always,
    Never,
}
