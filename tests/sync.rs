use std::fs;
use std::path::Path;
use std::process::Command;

use tempfile::tempdir;

fn write(root: &Path, path: &str, contents: &str) {
    let path = root.join(path);
    fs::create_dir_all(path.parent().unwrap()).unwrap();
    fs::write(path, contents).unwrap();
}

#[test]
fn sync_filters_payload_in_both_directions() {
    let excluded = [
        ".local/share/helper/__pycache__/helper.cpython-313.pyc",
        ".local/share/helper/cache.pyo",
        ".local/share/helper/.pytest_cache/state",
        ".local/share/helper/.mypy_cache/state",
        ".local/share/helper/.ruff_cache/state",
        ".local/share/helper/.git/config",
        ".vst/.gitkeep",
        ".config/obs-studio/.gitignore",
        ".config/obs-studio/logs/log.txt",
        ".config/obs-studio/plugin_config/settings.json",
        ".config/obs-studio/basic/profiles/test/service.json",
        ".config/obs-studio/basic/profiles/test/service.json.bak",
        ".bashrc.bak",
        ".bashrc.bak1",
    ];
    let included = [
        ".bashrc",
        ".gitignore",
        ".local/share/helper/helper.py",
        ".local/share/helper/README.md",
        ".vst/plugin.so",
    ];

    for direction in ["to-home", "to-repo"] {
        let temp = tempdir().unwrap();
        let repo = temp.path().join("repo");
        let content = repo.join("content");
        let home = temp.path().join("home");
        for path in included.iter().chain(&excluded) {
            write(&content, path, "repo");
            write(&home, path, "home");
        }
        let result = Command::new(env!("CARGO_BIN_EXE_dotfiles"))
            .args(["sync", direction, "--yes", "--root"])
            .arg(&repo)
            .arg("--home")
            .arg(&home)
            .args(["--only", "**", "--exclude", ".bashrc"])
            .output()
            .unwrap();
        assert!(result.status.success(), "{result:?}");
        let (dest, original, incoming) = if direction == "to-home" {
            (&home, "home", "repo")
        } else {
            (&content, "repo", "home")
        };
        for path in excluded.iter().chain(&[".bashrc"]) {
            assert_eq!(
                fs::read_to_string(dest.join(path)).unwrap(),
                original,
                "{path}"
            );
        }
        for path in &included[1..] {
            assert_eq!(
                fs::read_to_string(dest.join(path)).unwrap(),
                incoming,
                "{path}"
            );
        }
    }
}

#[test]
fn status_and_fresh_install_omit_generated_files() {
    let temp = tempdir().unwrap();
    let repo = temp.path().join("repo");
    let home = temp.path().join("home");
    write(&repo.join("content"), ".gitignore", "*.log");
    write(&repo.join("content"), ".vst/.gitkeep", "");
    write(
        &repo.join("content"),
        "helper/__pycache__/cache.pyc",
        "cache",
    );
    let status = Command::new(env!("CARGO_BIN_EXE_dotfiles"))
        .args(["status", "--root"])
        .arg(&repo)
        .arg("--home")
        .arg(&home)
        .output()
        .unwrap();
    assert!(status.status.success(), "{status:?}");
    let output = String::from_utf8(status.stdout).unwrap();
    assert!(output.contains(".gitignore"));
    assert!(!output.contains(".gitkeep"));
    assert!(!output.contains("__pycache__"));

    let result = Command::new(env!("CARGO_BIN_EXE_dotfiles"))
        .args(["sync", "to-home", "--yes", "--root"])
        .arg(&repo)
        .arg("--home")
        .arg(&home)
        .output()
        .unwrap();
    assert!(result.status.success(), "{result:?}");
    assert!(home.join(".gitignore").is_file());
    assert!(!home.join(".vst").exists());
    assert!(!home.join("helper").exists());
}

fn git(repo: &Path, args: &[&str]) {
    let status = Command::new("git")
        .arg("-C")
        .arg(repo)
        .args([
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.com",
            "-c",
            "commit.gpgsign=false",
            "-c",
            "core.hooksPath=/dev/null",
        ])
        .args(args)
        .status()
        .unwrap();
    assert!(status.success(), "git {args:?}");
}

/// A repo whose history removed some content/ paths, and a home that still
/// has them, plus a home file the repo never tracked.
fn repo_with_removed_paths(root: &Path) -> (std::path::PathBuf, std::path::PathBuf) {
    let repo = root.join("repo");
    let home = root.join("home");
    for path in [
        "kept",
        "removed",
        "edited",
        "uncommitted",
        "renamed",
        "nested/removed",
    ] {
        write(&repo.join("content"), path, path);
        write(&home, path, path);
    }
    write(&home, "edited", "changed at home");
    write(&home, "untracked", "mine");
    git(&repo, &["init", "-q"]);
    git(&repo, &["add", "-A"]);
    git(&repo, &["commit", "-q", "-m", "add"]);
    git(
        &repo,
        &[
            "rm",
            "-q",
            "content/removed",
            "content/edited",
            "content/nested/removed",
        ],
    );
    git(&repo, &["mv", "content/renamed", "content/moved"]);
    git(&repo, &["commit", "-q", "-m", "remove"]);
    fs::remove_file(repo.join("content/uncommitted")).unwrap();
    (repo, home)
}

fn sync(repo: &Path, home: &Path, args: &[&str]) -> std::process::Output {
    Command::new(env!("CARGO_BIN_EXE_dotfiles"))
        .args(["sync", "to-home", "--root"])
        .arg(repo)
        .arg("--home")
        .arg(home)
        .args(args)
        .output()
        .unwrap()
}

#[test]
fn delete_removes_home_files_the_repo_no_longer_has() {
    let temp = tempdir().unwrap();
    let (repo, home) = repo_with_removed_paths(temp.path());

    let result = sync(&repo, &home, &["--yes", "--delete"]);
    assert!(result.status.success(), "{result:?}");
    let output = String::from_utf8(result.stdout).unwrap();

    for gone in ["removed", "nested/removed", "uncommitted", "renamed"] {
        assert!(!home.join(gone).exists(), "{gone} should be deleted");
    }
    assert_eq!(fs::read_to_string(home.join("moved")).unwrap(), "renamed");
    assert_eq!(fs::read_to_string(home.join("kept")).unwrap(), "kept");
    assert_eq!(fs::read_to_string(home.join("untracked")).unwrap(), "mine");
    assert_eq!(
        fs::read_to_string(home.join("edited")).unwrap(),
        "changed at home"
    );
    assert!(output.contains("kept edited"), "{output}");
    assert!(output.contains("deleted:        4"), "{output}");
}

#[test]
fn delete_is_opt_in_and_respects_dry_run() {
    let temp = tempdir().unwrap();
    let (repo, home) = repo_with_removed_paths(temp.path());

    let result = sync(&repo, &home, &["--yes"]);
    assert!(result.status.success(), "{result:?}");
    assert!(home.join("removed").exists());

    let result = sync(&repo, &home, &["--yes", "--delete", "--dry-run"]);
    assert!(result.status.success(), "{result:?}");
    let output = String::from_utf8(result.stdout).unwrap();
    assert!(output.contains(&format!("delete {}", home.join("removed").display())));
    assert!(home.join("removed").exists());
}

#[test]
fn delete_only_applies_to_home() {
    let temp = tempdir().unwrap();
    let (repo, home) = repo_with_removed_paths(temp.path());
    let result = Command::new(env!("CARGO_BIN_EXE_dotfiles"))
        .args(["sync", "to-repo", "--yes", "--delete", "--root"])
        .arg(&repo)
        .arg("--home")
        .arg(&home)
        .output()
        .unwrap();
    assert!(!result.status.success());
}

#[test]
fn delete_leaves_files_inside_other_checkouts() {
    let temp = tempdir().unwrap();
    let (repo, home) = repo_with_removed_paths(temp.path());
    fs::create_dir_all(home.join("nested/.git")).unwrap();

    let result = sync(&repo, &home, &["--yes", "--delete"]);
    assert!(result.status.success(), "{result:?}");
    assert!(home.join("nested/removed").exists());
    assert!(!home.join("removed").exists());
}
