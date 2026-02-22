use anyhow::Result;
use dialoguer::Confirm;

pub fn confirm(prompt: &str, yes: bool) -> Result<bool> {
    if yes {
        return Ok(true);
    }
    let confirmed = Confirm::new()
        .with_prompt(prompt)
        .default(false)
        .interact()?;
    Ok(confirmed)
}
