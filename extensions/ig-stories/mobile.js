// Runs in the page's main world before Instagram's scripts, so the installed app
// looks like a phone to them. Request headers are rewritten by background.js.
(() => {
  if (!matchMedia("(display-mode: standalone)").matches) {
    return;
  }

  // Keep in sync with background.js.
  const MOBILE_UA =
    "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1";
  const SCREEN = { width: 430, height: 932 };

  const override = (prototype, name, value) =>
    Object.defineProperty(prototype, name, {
      get: () => value,
      configurable: true,
    });

  override(Navigator.prototype, "userAgent", MOBILE_UA);
  override(
    Navigator.prototype,
    "appVersion",
    MOBILE_UA.replace(/^Mozilla\//, ""),
  );
  override(Navigator.prototype, "platform", "iPhone");
  override(Navigator.prototype, "vendor", "Apple Computer, Inc.");
  override(Navigator.prototype, "maxTouchPoints", 5);
  // Safari has no client hints API at all.
  delete Navigator.prototype.userAgentData;

  for (const [name, value] of [
    ["width", SCREEN.width],
    ["height", SCREEN.height],
    ["availWidth", SCREEN.width],
    ["availHeight", SCREEN.height],
  ]) {
    override(Screen.prototype, name, value);
  }
  override(ScreenOrientation.prototype, "type", "portrait-primary");
  override(ScreenOrientation.prototype, "angle", 0);
  Object.defineProperty(window, "orientation", {
    value: 0,
    configurable: true,
  });
  // Chrome only exposes touch handlers when a touchscreen is present, and
  // feature checks probe elements and the document as well as the window.
  for (const target of [window, Document.prototype, Element.prototype]) {
    for (const name of [
      "ontouchstart",
      "ontouchmove",
      "ontouchend",
      "ontouchcancel",
    ]) {
      if (!(name in target)) {
        Object.defineProperty(target, name, {
          value: null,
          writable: true,
          configurable: true,
        });
      }
    }
  }

  // Answer pointer and hover queries as a touchscreen would by asking the
  // opposite question of the real mouse-driven device.
  const OPPOSITE = { fine: "coarse", coarse: "fine", hover: "none", none: "hover" };
  const nativeMatchMedia = window.matchMedia;
  window.matchMedia = function (query) {
    return nativeMatchMedia.call(
      this,
      query.replace(
        /(pointer|hover)\s*:\s*(fine|coarse|hover|none)/g,
        (match, feature, value) => `${feature}: ${OPPOSITE[value]}`,
      ),
    );
  };
})();
