// camera.js runs in the page's world, where it cannot reach the extension, so
// this answers its requests on the extension's behalf.
(() => {
  if (!matchMedia("(display-mode: standalone)").matches) {
    return;
  }

  const toFile = ({ data, type, name }) =>
    new File([Uint8Array.fromBase64(data)], name, { type });

  const answers = {
    async googlePhoto() {
      const { photo, error } = await chrome.runtime.sendMessage({
        type: "pickGooglePhoto",
      });
      if (error) {
        throw new Error(error);
      }
      return photo && toFile(photo);
    },
    async uiFont() {
      const response = await fetch(
        chrome.runtime.getURL("fonts/Nunito-Variable.ttf"),
      );
      return response.arrayBuffer();
    },
  };

  window.addEventListener("message", async (event) => {
    const { data } = event;
    if (
      event.source !== window ||
      data?.type !== "ig-plus:ask" ||
      !Object.hasOwn(answers, data.request)
    ) {
      return;
    }
    let reply;
    try {
      reply = { result: await answers[data.request]() };
    } catch (error) {
      reply = { error: error.message };
    }
    window.postMessage(
      { type: "ig-plus:answer", id: data.id, ...reply },
      location.origin,
    );
  });
})();
