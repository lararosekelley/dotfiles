// camera.js runs in the page's world, where it cannot reach the extension, so
// this relays its Google Photos requests to background.js.
(() => {
  if (!matchMedia("(display-mode: standalone)").matches) {
    return;
  }

  const toFile = ({ data, type, name }) =>
    new File([Uint8Array.fromBase64(data)], name, { type });

  window.addEventListener("message", async (event) => {
    if (
      event.source !== window ||
      event.data?.type !== "ig-stories:pick-google-photo"
    ) {
      return;
    }
    let reply;
    try {
      const { photo, error } = await chrome.runtime.sendMessage({
        type: "pickGooglePhoto",
      });
      reply = error ? { error } : { file: photo && toFile(photo) };
    } catch (error) {
      reply = { error: error.message };
    }
    window.postMessage(
      { type: "ig-stories:google-photo", id: event.data.id, ...reply },
      location.origin,
    );
  });
})();
