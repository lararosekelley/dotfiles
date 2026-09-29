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
        ".config/herdr/plugins.json",
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
