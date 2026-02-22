use anyhow::{anyhow, Result};
use std::path::PathBuf;

use crate::cli::{DirectionArg, StatusOptions};
use crate::fs::{build_records, collect_files, Filters};
use crate::model::{Direction, Status, SyncMode};

pub fn run(options: StatusOptions) -> Result<()> {
    let direction = match options.direction {
        DirectionArg::ToHome => Direction::ToHome,
        DirectionArg::ToRepo => Direction::ToRepo,
    };
    let mode = if options.symlink {
        SyncMode::Symlink
    } else {
        SyncMode::Copy
    };

    let (src_root, home_root) = resolve_paths(options.root, options.home)?;
    let filters = Filters::new(&options.only, &options.exclude)?;
    let rel_paths = collect_files(&src_root, &filters)?;
    let records = build_records(&rel_paths, &src_root, &home_root, direction, mode)?;

    print_records(&records);
    print_summary(&records);
    Ok(())
}

fn resolve_paths(root: Option<PathBuf>, home: Option<PathBuf>) -> Result<(PathBuf, PathBuf)> {
    let repo_root = root.unwrap_or(std::env::current_dir()?);
    let src_root = repo_root.join("content");
    if !src_root.is_dir() {
        return Err(anyhow!("expected src directory at {}", src_root.display()));
    }
    let home_root = match home {
        Some(path) => path,
        None => dirs::home_dir().ok_or_else(|| anyhow!("unable to resolve home directory"))?,
    };
    Ok((src_root, home_root))
}

fn print_records(records: &[crate::model::FileRecord]) {
    for record in records {
        match record.status {
            Status::Same | Status::SymlinkOk => continue,
            _ => {
                let label = status_label(&record.status);
                let path = record.rel_path.to_string_lossy();
                println!("{label: <16} {path}");
            }
        }
    }
}

fn print_summary(records: &[crate::model::FileRecord]) {
    let mut same = 0;
    let mut different = 0;
    let mut missing_source = 0;
    let mut missing_dest = 0;
    let mut symlink_ok = 0;
    let mut symlink_wrong = 0;
    let mut symlink_missing = 0;
    let mut conflict = 0;

    for record in records {
        match &record.status {
            Status::Same => same += 1,
            Status::Different => different += 1,
            Status::MissingSource => missing_source += 1,
            Status::MissingDest => missing_dest += 1,
            Status::SymlinkOk => symlink_ok += 1,
            Status::SymlinkWrong => symlink_wrong += 1,
            Status::SymlinkMissing => symlink_missing += 1,
            Status::Conflict(_) => conflict += 1,
        }
    }

    println!();
    println!("Summary");
    println!("  total:           {}", records.len());
    println!("  same:            {same}");
    println!("  different:       {different}");
    println!("  missing-source:  {missing_source}");
    println!("  missing-dest:    {missing_dest}");
    println!("  symlink-ok:      {symlink_ok}");
    println!("  symlink-wrong:   {symlink_wrong}");
    println!("  symlink-missing: {symlink_missing}");
    println!("  conflict:        {conflict}");
}

fn status_label(status: &Status) -> &'static str {
    match status {
        Status::Same => "same",
        Status::Different => "different",
        Status::MissingSource => "missing-source",
        Status::MissingDest => "missing-dest",
        Status::SymlinkOk => "symlink-ok",
        Status::SymlinkWrong => "symlink-wrong",
        Status::SymlinkMissing => "symlink-missing",
        Status::Conflict(_) => "conflict",
    }
}
