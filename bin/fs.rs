use anyhow::{anyhow, Context, Result};
use globset::{Glob, GlobSet, GlobSetBuilder};
use std::fs;
use std::io::Read;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

use crate::model::{Direction, FileRecord, Status, SyncMode};

pub struct Filters {
    only: Option<GlobSet>,
    exclude: Option<GlobSet>,
}

impl Filters {
    pub fn new(only: &[String], exclude: &[String]) -> Result<Self> {
        let only_set = build_globset(only)?;
        let exclude_set = build_globset(exclude)?;
        Ok(Self {
            only: only_set,
            exclude: exclude_set,
        })
    }

    pub fn is_included(&self, rel_path: &Path) -> bool {
        let path_str = path_to_slash(rel_path);
        if let Some(ref exclude) = self.exclude {
            if exclude.is_match(&path_str) {
                return false;
            }
        }
        if let Some(ref only) = self.only {
            return only.is_match(&path_str);
        }
        true
    }
}

fn build_globset(patterns: &[String]) -> Result<Option<GlobSet>> {
    if patterns.is_empty() {
        return Ok(None);
    }
    let mut builder = GlobSetBuilder::new();
    for pattern in patterns {
        let glob =
            Glob::new(pattern).with_context(|| format!("invalid glob pattern: {pattern}"))?;
        builder.add(glob);
    }
    Ok(Some(builder.build()?))
}

pub fn collect_files(src_root: &Path, filters: &Filters) -> Result<Vec<PathBuf>> {
    let mut files = Vec::new();
    for entry in WalkDir::new(src_root).follow_links(false) {
        let entry = entry?;
        if !entry.file_type().is_file() {
            continue;
        }
        let path = entry.path();
        let rel_path = path.strip_prefix(src_root)?;
        if filters.is_included(rel_path) {
            files.push(rel_path.to_path_buf());
        }
    }
    files.sort();
    Ok(files)
}

pub fn build_records(
    rel_paths: &[PathBuf],
    src_root: &Path,
    home_root: &Path,
    direction: Direction,
    mode: SyncMode,
) -> Result<Vec<FileRecord>> {
    let mut records = Vec::new();
    for rel in rel_paths {
        let repo_path = src_root.join(rel);
        let home_path = home_root.join(rel);
        let (source, dest) = match direction {
            Direction::ToHome => (repo_path, home_path),
            Direction::ToRepo => (home_path, repo_path),
        };
        let status = record_status(&source, &dest, direction, mode)?;
        records.push(FileRecord {
            rel_path: rel.clone(),
            src_path: source,
            dest_path: dest,
            status,
        });
    }
    Ok(records)
}

fn record_status(
    source: &Path,
    dest: &Path,
    direction: Direction,
    mode: SyncMode,
) -> Result<Status> {
    if mode == SyncMode::Symlink && direction == Direction::ToRepo {
        return Err(anyhow!("--symlink is only supported for sync to-home"));
    }

    if !source.exists() {
        return Ok(Status::MissingSource);
    }

    if mode == SyncMode::Symlink {
        if fs::symlink_metadata(dest).is_err() {
            return Ok(Status::MissingDest);
        }
        return symlink_status(source, dest);
    }

    if !dest.exists() {
        return Ok(Status::MissingDest);
    }

    if dest_is_dir(dest)? {
        return Ok(Status::Conflict("destination is a directory".to_string()));
    }

    let same = compare_files(source, dest)?;
    if same {
        Ok(Status::Same)
    } else {
        Ok(Status::Different)
    }
}

fn symlink_status(source: &Path, dest: &Path) -> Result<Status> {
    let meta = fs::symlink_metadata(dest)?;
    if meta.is_dir() {
        return Ok(Status::Conflict("destination is a directory".to_string()));
    }
    if !meta.file_type().is_symlink() {
        return Ok(Status::SymlinkMissing);
    }
    let target = fs::read_link(dest)?;
    let source_abs = fs::canonicalize(source)
        .with_context(|| format!("failed to resolve source path: {}", source.display()))?;
    let target_abs = if target.is_absolute() {
        target
    } else {
        dest.parent().unwrap_or_else(|| Path::new("/")).join(target)
    };
    let target_abs = fs::canonicalize(&target_abs).unwrap_or(target_abs);

    if source_abs == target_abs {
        Ok(Status::SymlinkOk)
    } else {
        Ok(Status::SymlinkWrong)
    }
}

fn compare_files(source: &Path, dest: &Path) -> Result<bool> {
    let source_meta = fs::metadata(source)?;
    let dest_meta = fs::metadata(dest)?;
    if source_meta.len() != dest_meta.len() {
        return Ok(false);
    }
    let source_hash = hash_file(source)?;
    let dest_hash = hash_file(dest)?;
    Ok(source_hash == dest_hash)
}

fn hash_file(path: &Path) -> Result<blake3::Hash> {
    let mut file = fs::File::open(path)?;
    let mut hasher = blake3::Hasher::new();
    let mut buffer = [0u8; 8192];
    loop {
        let read = file.read(&mut buffer)?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(hasher.finalize())
}

fn dest_is_dir(dest: &Path) -> Result<bool> {
    Ok(fs::metadata(dest).map(|m| m.is_dir()).unwrap_or(false))
}

pub fn ensure_parent_dir(path: &Path) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    Ok(())
}

pub fn remove_target(path: &Path) -> Result<()> {
    let meta = fs::symlink_metadata(path)?;
    if meta.is_dir() {
        fs::remove_dir_all(path)?;
    } else {
        fs::remove_file(path)?;
    }
    Ok(())
}

pub fn backup_path(path: &Path) -> Result<PathBuf> {
    let file_name = path
        .file_name()
        .ok_or_else(|| anyhow!("invalid file name for backup"))?;
    let file_name = file_name.to_string_lossy();
    let mut candidate = path.with_file_name(format!("{file_name}.bak"));
    if !candidate.exists() {
        return Ok(candidate);
    }
    for idx in 1..1000 {
        candidate = path.with_file_name(format!("{file_name}.bak{idx}"));
        if !candidate.exists() {
            return Ok(candidate);
        }
    }
    Err(anyhow!(
        "unable to find backup filename for {}",
        path.display()
    ))
}

pub fn path_to_slash(path: &Path) -> String {
    let parts: Vec<_> = path
        .components()
        .map(|component| component.as_os_str().to_string_lossy())
        .collect();
    parts.join("/")
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn filters_only_and_exclude() -> Result<()> {
        let filters = Filters::new(&["**/*.sh".to_string()], &["**/skip*".to_string()])?;
        assert!(filters.is_included(Path::new("scripts/run.sh")));
        assert!(!filters.is_included(Path::new("scripts/skip.sh")));
        assert!(!filters.is_included(Path::new("README.md")));
        Ok(())
    }

    #[test]
    fn compare_files_detects_changes() -> Result<()> {
        let dir = tempdir()?;
        let a = dir.path().join("a.txt");
        let b = dir.path().join("b.txt");
        fs::write(&a, "hello")?;
        fs::write(&b, "hello")?;
        assert!(compare_files(&a, &b)?);
        fs::write(&b, "world")?;
        assert!(!compare_files(&a, &b)?);
        Ok(())
    }
}
