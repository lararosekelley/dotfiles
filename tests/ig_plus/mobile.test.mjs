import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

const source = await readFile(
  new URL("../../extensions/ig-plus/mobile.js", import.meta.url),
  "utf8",
);

const DESKTOP_UA = "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Firefox/140.0";
const ANDROID_UA =
  "Mozilla/5.0 (Android 15; Mobile; rv:140.0) Gecko/140.0 Firefox/140.0";

// Loads mobile.js into a stand-in page and reports what it decided.
function loadPage({
  userAgent = DESKTOP_UA,
  hash = "",
  stored = {},
  runs = 1,
} = {}) {
  const storage = new Map(Object.entries(stored));
  const location = { hash, pathname: "/", search: "" };
  class Navigator {}
  Object.defineProperty(Navigator.prototype, "userAgent", {
    get: () => userAgent,
    configurable: true,
  });
  const window = {};
  // Reports whether a touchscreen query comes back as one.
  const nativeMatchMedia = (query) => ({
    matches: /pointer: coarse/.test(query),
  });
  const page = {
    window,
    location,
    navigator: new Navigator(),
    Navigator,
    Screen: class {},
    ScreenOrientation: class {},
    Document: class {},
    Element: class {},
    document: { documentElement: { dataset: {} } },
    matchMedia: nativeMatchMedia,
    sessionStorage: {
      getItem: (key) => storage.get(key) ?? null,
      setItem: (key, value) => storage.set(key, value),
    },
    history: {
      state: null,
      replaceState(state, title, url) {
        location.hash = "";
        this.url = url;
      },
    },
  };
  Object.assign(window, page);
  const context = vm.createContext(page);
  for (let run = 0; run < runs; run++) {
    vm.runInContext(source, context);
  }
  return {
    screenWidth: Object.getOwnPropertyDescriptor(
      page.Screen.prototype,
      "width",
    )?.get(),
    coarse: () => window.matchMedia("(pointer: fine)").matches,
    phone: page.document.documentElement.dataset.igPlusPhone,
    userAgent: page.navigator.userAgent,
    storage,
    history: page.history,
  };
}

test("leaves ordinary desktop tabs alone", () => {
  const page = loadPage();
  assert.equal(page.phone, undefined);
  assert.equal(page.userAgent, DESKTOP_UA);
});

test("turns the phone window's tab into a phone and remembers it", () => {
  const page = loadPage({ hash: "#ig-plus-phone" });
  assert.equal(page.phone, "emulated");
  assert.match(page.userAgent, /iPhone/);
  assert.equal(page.storage.get("ig-plus:phone"), "1");
  assert.equal(page.history.url, "/");
});

test("keeps a phone tab a phone after it navigates", () => {
  const page = loadPage({ stored: { "ig-plus:phone": "1" } });
  assert.equal(page.phone, "emulated");
});

test("marks real phones without pretending to be another", () => {
  const page = loadPage({ userAgent: ANDROID_UA });
  assert.equal(page.phone, "native");
  assert.equal(page.userAgent, ANDROID_UA);
});

// Firefox already reports the rewritten user agent to phone window pages.
test("emulates a phone window that already reports an iPhone", () => {
  const page = loadPage({
    userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X)",
    stored: { "ig-plus:phone": "1" },
  });
  assert.equal(page.phone, "emulated");
  assert.equal(page.screenWidth, 430);
});

test("stays a touchscreen when injected twice", () => {
  const page = loadPage({ stored: { "ig-plus:phone": "1" }, runs: 2 });
  assert.equal(page.coarse(), true);
});
