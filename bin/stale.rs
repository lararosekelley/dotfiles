//! Home files left behind by paths removed from `content/`, for `sync to-home
//! --delete`. Git history is the record of what the repo used to install, so a
//! home file is a candidate only if its path was once tracked under `content/`.

use anyhow::{anyhow, Result};
use std::collections::HashSet;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::fs::Filters;

#[derive(Debug)]
pub struct StaleFile {
    pub rel_path: PathBuf,
    pub home_path: PathBuf,
    /// The home copy still matches the repo's last version of the file, so
    /// deleting it loses nothing.
    pub unchanged: bool,
}

pub fn find(
    repo_root: &Path,
    home_root: &Path,
    filters: &Filters,
    current: &[PathBuf],
) -> Result<Vec<StaleFile>> {
    git(repo_root, &["rev-parse", "--git-dir"]).map_err(|_| {
        anyhow!(
            "--delete needs {} to be a git checkout",
            repo_root.display()
        )
    })?;

    let current: HashSet<&PathBuf> = current.iter().collect();
    let mut seen = HashSet::new();
    let mut stale = Vec::new();

    for (rev, repo_path) in removed_paths(repo_root)? {
        let Some(rel) = repo_path.strip_prefix("content/") else {
            continue;
        };
        let rel_path = PathBuf::from(rel);
        if !seen.insert(rel_path.clone())
            || current.contains(&rel_path)
            || repo_root.join(&repo_path).exists()
            || !filters.is_included(&rel_path)
        {
            continue;
        }

        let home_path = home_root.join(&rel_path);
        let Ok(meta) = std::fs::symlink_metadata(&home_path) else {
            continue;
        };
        if meta.is_dir() || in_other_checkout(home_root, &rel_path) {
            continue;
        }

        let unchanged = if meta.file_type().is_symlink() {
            // a symlink install points into content/, where the file no longer is
            std::fs::read_link(&home_path)? == std::fs::canonicalize(repo_root)?.join(&repo_path)
        } else {
            let last = git_bytes(
                repo_root,
                &["cat-file", "blob", &format!("{rev}:{repo_path}")],
            )?;
            std::fs::read(&home_path)? == last
        };

        stale.push(StaleFile {
            rel_path,
            home_path,
            unchanged,
        });
    }

    stale.sort_by(|a, b| a.rel_path.cmp(&b.rel_path));
    Ok(stale)
}

/// Whether a directory between home and the file is a git checkout, as when a
/// config moved out of this repo into one of its own.
fn in_other_checkout(home_root: &Path, rel_path: &Path) -> bool {
    rel_path
        .ancestors()
        .skip(1)
        .filter(|dir| !dir.as_os_str().is_empty())
        .any(|dir| home_root.join(dir).join(".git").exists())
}

/// Paths deleted from `content/`, each with the revision holding its last
/// version: uncommitted deletions first, then commits from newest to oldest.
fn removed_paths(repo_root: &Path) -> Result<Vec<(String, String)>> {
    let mut removed = Vec::new();

    if let Ok(out) = git(
        repo_root,
        &[
            "diff",
            "--no-renames",
            "--name-only",
            "--diff-filter=D",
            "HEAD",
            "--",
            "content/",
        ],
    ) {
        removed.extend(
            out.lines()
                .map(|path| ("HEAD".to_string(), path.to_string())),
        );
    }

    let log = git(
        repo_root,
        &[
            "log",
            "--no-renames",
            "--diff-filter=D",
            "--name-only",
            "--format=commit %H",
            "--",
            "content/",
        ],
    )
    .unwrap_or_default();
    let mut rev = String::new();
    for line in log.lines() {
        if let Some(hash) = line.strip_prefix("commit ") {
            rev = format!("{hash}^");
        } else if !line.is_empty() {
            removed.push((rev.clone(), line.to_string()));
        }
    }

    Ok(removed)
}

fn git(repo_root: &Path, args: &[&str]) -> Result<String> {
    Ok(String::from_utf8(git_bytes(repo_root, args)?)?)
}

fn git_bytes(repo_root: &Path, args: &[&str]) -> Result<Vec<u8>> {
    let output = Command::new("git")
        .arg("-C")
        .arg(repo_root)
        .args(["-c", "core.quotepath=off"])
        .args(args)
        .output()?;
    if !output.status.success() {
        return Err(anyhow!(
            "git {} failed: {}",
            args.join(" "),
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }
    Ok(output.stdout)
}
