use anyhow::Result;

use crate::cli::SyncOptions;
use crate::model::Direction;

use super::sync::run_sync;

pub fn run(options: SyncOptions) -> Result<()> {
    run_sync(options, Direction::ToHome, true)
}
