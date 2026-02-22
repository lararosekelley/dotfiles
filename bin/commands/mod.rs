use anyhow::Result;

use crate::cli::{Cli, Command, SyncCommand};

mod status;
mod sync;
mod sync_to_home;
mod sync_to_repo;

pub fn run(cli: Cli) -> Result<()> {
    match cli.command {
        Command::Status(options) => status::run(options),
        Command::Sync(sync) => match sync.command {
            SyncCommand::ToHome(options) => sync_to_home::run(options),
            SyncCommand::ToRepo(options) => sync_to_repo::run(options),
        },
    }
}
