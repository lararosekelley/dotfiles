const DEFAULTS = { hideFeed: true, hideReels: true };
const message = document.getElementById("message");
const phone = document.getElementById("phone");

chrome.storage.sync.get(DEFAULTS).then((settings) => {
  for (const input of document.querySelectorAll("input[type=checkbox]")) {
    input.checked = settings[input.name];
    input.onchange = () =>
      chrome.storage.sync.set({ [input.name]: input.checked });
  }
});

// Firefox for Android has no windows, and Instagram is already a phone there.
phone.hidden = !chrome.windows;
phone.onclick = async () => {
  const { error } = await chrome.runtime.sendMessage({
    type: "openPhoneWindow",
  });
  if (error) {
    message.textContent = `Could not open the phone window: ${error}`;
    message.hidden = false;
  } else {
    window.close();
  }
};
