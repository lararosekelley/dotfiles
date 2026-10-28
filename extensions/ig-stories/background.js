const MOBILE_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1";

// Instagram refuses to add to a story while the viewport is landscape.
const PHONE_WINDOW = { width: 430, height: 860 };

const pending = new Set();

// Applies the same overrides as DevTools device mode. They last as long as the
// debugger stays attached, which is until the tab closes.
async function emulateMobile(tabId) {
  const target = { tabId };
  const send = (method, params) =>
    chrome.debugger.sendCommand(target, method, params);

  await chrome.debugger.attach(target, "1.3");
  await send("Emulation.setUserAgentOverride", {
    userAgent: MOBILE_UA,
    platform: "iPhone",
  });
  // Zero sizes keep the window's own viewport, which handleTab makes portrait.
  await send("Emulation.setDeviceMetricsOverride", {
    width: 0,
    height: 0,
    deviceScaleFactor: 0,
    mobile: true,
    screenWidth: PHONE_WINDOW.width,
    screenHeight: PHONE_WINDOW.height,
    screenOrientation: { type: "portraitPrimary", angle: 0 },
  });
  await send("Emulation.setTouchEmulationEnabled", {
    enabled: true,
    maxTouchPoints: 5,
  });
  await send("Emulation.setEmitTouchEventsForMouse", {
    enabled: true,
    configuration: "mobile",
  });
}

async function isInstagramApp(tab) {
  if (!tab.url || !new URL(tab.url).hostname.endsWith("instagram.com")) {
    return false;
  }
  const window = await chrome.windows.get(tab.windowId);
  return window.type === "app";
}

// Also true when DevTools is attached, which already handles emulation.
async function isAttached(tabId) {
  const targets = await chrome.debugger.getTargets();
  return targets.some((target) => target.tabId === tabId && target.attached);
}

async function handleTab(tab) {
  if (pending.has(tab.id)) {
    return;
  }
  pending.add(tab.id);
  try {
    if ((await isInstagramApp(tab)) && !(await isAttached(tab.id))) {
      await chrome.windows.update(tab.windowId, PHONE_WINDOW);
      await emulateMobile(tab.id);
      // The page already started loading as desktop before the attach.
      await chrome.tabs.reload(tab.id);
    }
  } catch (error) {
    console.warn(`Could not emulate mobile in tab ${tab.id}:`, error);
  } finally {
    pending.delete(tab.id);
  }
}

async function handleOpenTabs() {
  const tabs = await chrome.tabs.query({ url: "https://*.instagram.com/*" });
  await Promise.all(tabs.map(handleTab));
}

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === "loading") {
    handleTab(tab);
  }
});

chrome.runtime.onStartup.addListener(handleOpenTabs);
chrome.runtime.onInstalled.addListener(handleOpenTabs);
