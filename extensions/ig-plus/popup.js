const DEFAULTS = { hideFeed: true, hideReels: true };

chrome.storage.sync.get(DEFAULTS).then((settings) => {
  for (const input of document.querySelectorAll("input[type=checkbox]")) {
    input.checked = settings[input.name];
    input.onchange = () =>
      chrome.storage.sync.set({ [input.name]: input.checked });
  }
});
