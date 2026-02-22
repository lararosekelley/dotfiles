use anyhow::{anyhow, Result};
use std::path::PathBuf;

use crate::cli::SyncOptions;
use crate::fs::{
    backup_path, build_records, collect_files, ensure_parent_dir, remove_target, Filters,
};
use crate::model::{Direction, Status, SyncMode};
use crate::ui::confirm;

pub fn run_sync(options: SyncOptions, direction: Direction, allow_symlink: bool) -> Result<()> {
    if options.symlink && !allow_symlink {
        return Err(anyhow!("--symlink is only supported for sync to-home"));
    }

    let mode = if options.symlink {
        SyncMode::Symlink
    } else {
        SyncMode::Copy
    };

    let root = options.root.clone();
    let home = options.home.clone();
    let (src_root, home_root) = resolve_paths(root, home)?;
    let filters = Filters::new(&options.only, &options.exclude)?;
    let rel_paths = collect_files(&src_root, &filters)?;
    let records = build_records(&rel_paths, &src_root, &home_root, direction, mode)?;

    apply_sync(&records, mode, &options)
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

fn apply_sync(
    records: &[crate::model::FileRecord],
    mode: SyncMode,
    options: &SyncOptions,
) -> Result<()> {
    let mut copied = 0;
    let mut linked = 0;
    let mut skipped = 0;
    let mut missing_source = 0;
    let mut conflicts = 0;

    for record in records {
        let action = action_for_status(&record.status, mode);
        match action {
            SyncAction::Skip => {
                skipped += 1;
                continue;
            }
            SyncAction::MissingSource => {
                missing_source += 1;
                println!("missing source: {}", record.rel_path.to_string_lossy());
                continue;
            }
            SyncAction::Apply => {
                if matches!(record.status, Status::Conflict(_)) {
                    conflicts += 1;
                }
            }
        }

        let verb = match mode {
            SyncMode::Copy => "Update",
            SyncMode::Symlink => "Link",
        };
        let prompt = prompt_for_status(&record.status, verb, &record.rel_path);
        if !confirm(&prompt, options.yes)? {
            skipped += 1;
            continue;
        }

        if options.backup {
            maybe_backup(record, options.dry_run)?;
        }

        if record.dest_path.exists() {
            if options.dry_run {
                println!("remove {}", record.dest_path.display());
            } else {
                remove_target(&record.dest_path)?;
            }
        }

        ensure_parent_dir(&record.dest_path)?;

        match mode {
            SyncMode::Copy => {
                if options.dry_run {
                    println!(
                        "copy {} -> {}",
                        record.src_path.display(),
                        record.dest_path.display()
                    );
                } else {
                    std::fs::copy(&record.src_path, &record.dest_path)?;
                }
                copied += 1;
            }
            SyncMode::Symlink => {
                if options.dry_run {
                    println!(
                        "symlink {} -> {}",
                        record.src_path.display(),
                        record.dest_path.display()
                    );
                } else {
                    create_symlink(&record.src_path, &record.dest_path)?;
                }
                linked += 1;
            }
        }
    }

    println!();
    println!("Summary");
    println!("  copied:         {copied}");
    println!("  linked:         {linked}");
    println!("  skipped:        {skipped}");
    println!("  missing-source: {missing_source}");
    println!("  conflicts:      {conflicts}");
    Ok(())
}

fn maybe_backup(record: &crate::model::FileRecord, dry_run: bool) -> Result<()> {
    if !record.dest_path.exists() {
        return Ok(());
    }
    let meta = std::fs::symlink_metadata(&record.dest_path)?;
    if meta.is_dir() {
        println!(
            "backup skipped for directory {}",
            record.dest_path.display()
        );
        return Ok(());
    }
    let backup = backup_path(&record.dest_path)?;
    if dry_run {
        println!(
            "backup {} -> {}",
            record.dest_path.display(),
            backup.display()
        );
        return Ok(());
    }
    std::fs::copy(&record.dest_path, &backup)?;
    Ok(())
}

fn action_for_status(status: &Status, mode: SyncMode) -> SyncAction {
    match status {
        Status::Same | Status::SymlinkOk => SyncAction::Skip,
        Status::MissingSource => SyncAction::MissingSource,
        Status::MissingDest => SyncAction::Apply,
        Status::Different => SyncAction::Apply,
        Status::Conflict(_) => SyncAction::Apply,
        Status::SymlinkWrong | Status::SymlinkMissing => {
            if mode == SyncMode::Symlink {
                SyncAction::Apply
            } else {
                SyncAction::Skip
            }
        }
    }
}

fn prompt_for_status(status: &Status, verb: &str, rel_path: &std::path::Path) -> String {
    let action = match status {
        Status::MissingDest => "Create",
        Status::Different => "Update",
        Status::Conflict(_) => "Replace",
        Status::SymlinkWrong => "Relink",
        Status::SymlinkMissing => "Link",
        Status::MissingSource => "Skip",
        Status::Same | Status::SymlinkOk => verb,
    };
    format!("{action} {}?", rel_path.to_string_lossy())
}

enum SyncAction {
    Skip,
    MissingSource,
    Apply,
}

#[cfg(unix)]
fn create_symlink(source: &std::path::Path, dest: &std::path::Path) -> Result<()> {
    let source_abs = std::fs::canonicalize(source)?;
    std::os::unix::fs::symlink(source_abs, dest)?;
    Ok(())
}

#[cfg(not(unix))]
fn create_symlink(_source: &std::path::Path, _dest: &std::path::Path) -> Result<()> {
    Err(anyhow!("symlink mode is only supported on unix"))
}
