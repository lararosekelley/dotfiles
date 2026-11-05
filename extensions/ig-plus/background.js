// Keep in sync with mobile.js.
const MOBILE_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1";

// Safari sends no client hints, so drop Chrome's rather than contradict the UA.
const CLIENT_HINT_HEADERS = [
  "sec-ch-ua",
  "sec-ch-ua-mobile",
  "sec-ch-ua-platform",
  "sec-ch-ua-full-version-list",
  "sec-ch-ua-platform-version",
  "sec-ch-ua-model",
];

// Instagram refuses to add to a story while the viewport is landscape.
const PHONE_WINDOW = { width: 430, height: 860 };

const pending = new Set();

function mobileRule(tabId) {
  return {
    id: tabId,
    priority: 1,
    action: {
      type: "modifyHeaders",
      requestHeaders: [
        { header: "user-agent", operation: "set", value: MOBILE_UA },
        ...CLIENT_HINT_HEADERS.map((header) => ({
          header,
          operation: "remove",
        })),
      ],
    },
    condition: {
      tabIds: [tabId],
      requestDomains: ["instagram.com"],
      // Without a list, rules skip main_frame, and Instagram decides whether
      // to serve the mobile app from the page request's User-Agent.
      resourceTypes: ["main_frame", "sub_frame", "xmlhttprequest", "other"],
    },
  };
}

// Each app tab gets a session rule whose id is its tab id, so the rules double
// as the record of which tabs are already handled.
async function isMobileTab(tabId) {
  const rules = await chrome.declarativeNetRequest.getSessionRules();
  return rules.some((rule) => rule.id === tabId);
}

async function isInstagramApp(tab) {
  if (!tab.url || !new URL(tab.url).hostname.endsWith("instagram.com")) {
    return false;
  }
  const window = await chrome.windows.get(tab.windowId);
  return window.type === "app";
}

async function handleTab(tab) {
  if (pending.has(tab.id)) {
    return;
  }
  pending.add(tab.id);
  try {
    if ((await isInstagramApp(tab)) && !(await isMobileTab(tab.id))) {
      await chrome.windows.update(tab.windowId, PHONE_WINDOW);
      await chrome.declarativeNetRequest.updateSessionRules({
        addRules: [mobileRule(tab.id)],
      });
      // The page already started loading with desktop headers, and the
      // service worker may hold a desktop copy, so skip its cache.
      await chrome.tabs.reload(tab.id, { bypassCache: true });
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

const PICKER_API = "https://photospicker.googleapis.com/v1";
const PICKER_WINDOW = { width: 1000, height: 800 };
// The story is 1080x1920, so this leaves room to zoom without fetching originals.
const PHOTO_SIZE = "=w3840-h3840";

class PickerError extends Error {
  constructor(path, status) {
    super(`Google Photos request ${path} failed with ${status}`);
    this.status = status;
  }
}

async function authToken() {
  const { token } = await chrome.identity.getAuthToken({ interactive: true });
  return token;
}

async function pickerRequest(token, path, options = {}) {
  const response = await fetch(`${PICKER_API}/${path}`, {
    ...options,
    headers: { Authorization: `Bearer ${token}`, ...options.headers },
  });
  if (!response.ok) {
    throw new PickerError(path, response.status);
  }
  const body = await response.text();
  return body ? JSON.parse(body) : null;
}

function createSession(token) {
  return pickerRequest(token, "sessions", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ pickingConfig: { maxItemCount: "1" } }),
  });
}

// Durations arrive as strings such as "5s" or "3.5s".
function milliseconds(duration, fallback) {
  const seconds = parseFloat(duration);
  return Number.isFinite(seconds) ? seconds * 1000 : fallback;
}

// Resolves true once the picker reports a selection, or false if its window
// closes or the session expires without one.
async function waitForPick(token, session, windowId) {
  const interval = milliseconds(session.pollingConfig?.pollInterval, 5000);
  const deadline =
    Date.now() + milliseconds(session.pollingConfig?.timeoutIn, 600000);
  while (Date.now() < deadline) {
    // Check the window first: it closes itself right after a selection.
    const open = await chrome.windows.get(windowId).then(
      () => true,
      () => false,
    );
    const { mediaItemsSet } = await pickerRequest(
      token,
      `sessions/${session.id}`,
    );
    if (mediaItemsSet) {
      return true;
    }
    if (!open) {
      return false;
    }
    await new Promise((resolve) => setTimeout(resolve, interval));
  }
  chrome.windows.remove(windowId).catch(() => {});
  return false;
}

async function download(token, { baseUrl, mimeType, filename }) {
  const video = mimeType.startsWith("video/");
  const response = await fetch(baseUrl + (video ? "=dv" : PHOTO_SIZE), {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) {
    throw new PickerError("download", response.status);
  }
  const bytes = new Uint8Array(await response.arrayBuffer());
  return {
    data: bytes.toBase64(),
    type: response.headers.get("content-type") ?? mimeType,
    name: filename,
  };
}

// Returns the picked photo or video as base64, or null if nothing was picked.
async function pickGooglePhoto() {
  let token = await authToken();
  let session;
  try {
    session = await createSession(token);
  } catch (error) {
    if (error.status !== 401) {
      throw error;
    }
    // Chrome can hand back a cached token that Google has since revoked.
    await chrome.identity.removeCachedAuthToken({ token });
    token = await authToken();
    session = await createSession(token);
  }
  try {
    const window = await chrome.windows.create({
      url: `${session.pickerUri}/autoclose`,
      type: "popup",
      ...PICKER_WINDOW,
    });
    if (!(await waitForPick(token, session, window.id))) {
      return null;
    }
    const {
      mediaItems: [item],
    } = await pickerRequest(
      token,
      `mediaItems?sessionId=${session.id}&pageSize=1`,
    );
    return await download(token, item.mediaFile);
  } finally {
    pickerRequest(token, `sessions/${session.id}`, { method: "DELETE" }).catch(
      () => {},
    );
  }
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "pickGooglePhoto") {
    pickGooglePhoto().then(
      (photo) => sendResponse({ photo }),
      (error) => sendResponse({ error: error.message }),
    );
    return true;
  }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === "loading") {
    handleTab(tab);
  }
});

chrome.tabs.onRemoved.addListener((tabId) => {
  chrome.declarativeNetRequest.updateSessionRules({ removeRuleIds: [tabId] });
});

chrome.runtime.onStartup.addListener(handleOpenTabs);

// Session rules survive extension reloads, so replace any from an older
// version.
chrome.runtime.onInstalled.addListener(async () => {
  const rules = await chrome.declarativeNetRequest.getSessionRules();
  await chrome.declarativeNetRequest.updateSessionRules({
    removeRuleIds: rules.map((rule) => rule.id),
  });
  await handleOpenTabs();
});
