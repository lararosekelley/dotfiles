use anyhow::Result;
use console::{style, Style};
use similar::{ChangeTag, TextDiff};
use std::fs;
use std::path::Path;

/// Number of unchanged lines kept around each change, as in `diff -U3`.
const CONTEXT_LINES: usize = 3;

/// Colours follow git's defaults: removals red, additions green, file headers
/// bold, and the elision between hunks cyan. `console` drops the escapes on its
/// own when stdout is not a terminal or `NO_COLOR` is set.
fn line_style(tag: ChangeTag) -> Style {
    match tag {
        ChangeTag::Delete => Style::new().red(),
        ChangeTag::Insert => Style::new().green(),
        ChangeTag::Equal => Style::new(),
    }
}

/// A unified diff of the destination's current contents against what the source
/// would write, or a one-line note when a text diff is not meaningful.
pub fn render(src: &Path, dest: &Path) -> Result<String> {
    let src_bytes = fs::read(src)?;
    let dest_bytes = fs::read(dest)?;

    let (src_text, dest_text) = match (text_of(&src_bytes), text_of(&dest_bytes)) {
        (Some(src_text), Some(dest_text)) => (src_text, dest_text),
        _ => {
            return Ok(format!(
                "  binary files differ ({} -> {} bytes)\n",
                dest_bytes.len(),
                src_bytes.len()
            ))
        }
    };

    let diff = TextDiff::from_lines(dest_text, src_text);
    let mut out = String::new();
    out.push_str(&format!(
        "  {}\n",
        style(format!("--- {} (current)", dest.display())).bold()
    ));
    out.push_str(&format!(
        "  {}\n",
        style(format!("+++ {} (incoming)", src.display())).bold()
    ));

    for (idx, group) in diff.grouped_ops(CONTEXT_LINES).iter().enumerate() {
        if idx > 0 {
            out.push_str(&format!("  {}\n", style("...").cyan()));
        }
        for op in group {
            for change in diff.iter_changes(op) {
                let sign = match change.tag() {
                    ChangeTag::Delete => '-',
                    ChangeTag::Insert => '+',
                    ChangeTag::Equal => ' ',
                };
                let text = change.value().trim_end_matches('\n');
                // style the sign and the text as one run so the whole line is
                // coloured, matching how git renders a hunk
                let line = line_style(change.tag()).apply_to(format!("{sign}{text}"));
                out.push_str(&format!("  {line}\n"));
            }
        }
    }

    Ok(out)
}

/// A one-line summary for a file that exists only at the source.
pub fn render_new_file(src: &Path) -> Result<String> {
    let bytes = fs::read(src)?;
    match text_of(&bytes) {
        Some(text) => Ok(format!(
            "  new file, {} line(s), {} bytes\n",
            text.lines().count(),
            bytes.len()
        )),
        None => Ok(format!("  new binary file, {} bytes\n", bytes.len())),
    }
}

/// Treat a file as text only if it is valid UTF-8 and holds no NUL bytes, so
/// binary configs never get dumped into the terminal.
fn text_of(bytes: &[u8]) -> Option<&str> {
    if bytes.contains(&0) {
        return None;
    }
    std::str::from_utf8(bytes).ok()
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    /// Content assertions strip escapes so they hold whether or not colour is
    /// enabled for the process running the tests.
    fn plain(out: &str) -> String {
        console::strip_ansi_codes(out).into_owned()
    }

    #[test]
    fn renders_changed_lines() -> Result<()> {
        let dir = tempdir()?;
        let src = dir.path().join("src.txt");
        let dest = dir.path().join("dest.txt");
        fs::write(&src, "keep\nnew\n")?;
        fs::write(&dest, "keep\nold\n")?;

        let out = plain(&render(&src, &dest)?);
        assert!(out.contains("(current)"));
        assert!(out.contains("(incoming)"));
        assert!(out.contains("   keep"));
        assert!(out.contains("  -old"));
        assert!(out.contains("  +new"));
        Ok(())
    }

    #[test]
    fn colours_removals_red_and_additions_green() -> Result<()> {
        let dir = tempdir()?;
        let src = dir.path().join("src.txt");
        let dest = dir.path().join("dest.txt");
        fs::write(&src, "new\n")?;
        fs::write(&dest, "old\n")?;

        // no other test flips this global, so forcing it on here is safe
        console::set_colors_enabled(true);
        let out = render(&src, &dest)?;

        assert!(
            out.contains("\u{1b}[31m-old"),
            "removal should be red: {out:?}"
        );
        assert!(
            out.contains("\u{1b}[32m+new"),
            "addition should be green: {out:?}"
        );
        Ok(())
    }

    #[test]
    fn reports_binary_files_without_dumping_them() -> Result<()> {
        let dir = tempdir()?;
        let src = dir.path().join("src.bin");
        let dest = dir.path().join("dest.bin");
        fs::write(&src, [0u8, 1, 2])?;
        fs::write(&dest, [0u8, 9])?;

        let out = plain(&render(&src, &dest)?);
        assert_eq!(out, "  binary files differ (2 -> 3 bytes)\n");
        Ok(())
    }

    #[test]
    fn summarises_new_files() -> Result<()> {
        let dir = tempdir()?;
        let src = dir.path().join("src.txt");
        fs::write(&src, "one\ntwo\n")?;

        let out = render_new_file(&src)?;
        assert!(out.contains("new file, 2 line(s), 8 bytes"));
        Ok(())
    }
}
