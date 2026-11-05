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

// Phone tabs are Instagram in the installed app or in a phone window, which is
// a popup. Firefox for Android has no windows, and no need for either.
async function isPhoneTab(tab) {
  if (
    !chrome.windows ||
    !tab.url ||
    !new URL(tab.url).hostname.endsWith("instagram.com")
  ) {
    return false;
  }
  const window = await chrome.windows.get(tab.windowId);
  return window.type === "app" || window.type === "popup";
}

// Opens Instagram in a phone-sized window, or focuses the one already open.
// The marker hash tells mobile.js the tab is a phone.
async function openPhoneWindow() {
  for (const rule of await chrome.declarativeNetRequest.getSessionRules()) {
    const tab = await chrome.tabs.get(rule.id).catch(() => null);
    const window = tab && (await chrome.windows.get(tab.windowId));
    if (window?.type === "popup") {
      await chrome.windows.update(window.id, { focused: true });
      return;
    }
  }
  const window = await chrome.windows.create({
    url: "about:blank",
    type: "popup",
    ...PHONE_WINDOW,
  });
  const [tab] = window.tabs;
  // Rewrite headers before the first request, so no reload is needed.
  await chrome.declarativeNetRequest.updateSessionRules({
    addRules: [mobileRule(tab.id)],
  });
  await chrome.tabs.update(tab.id, {
    url: "https://www.instagram.com/#ig-plus-phone",
  });
}

async function handleTab(tab) {
  if (pending.has(tab.id)) {
    return;
  }
  pending.add(tab.id);
  try {
    if ((await isPhoneTab(tab)) && !(await isMobileTab(tab.id))) {
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

// Firefox has no getAuthToken, so it signs in through a "Web application"
// OAuth client instead, whose redirect URI is chrome.identity.getRedirectURL().
const WEB_CLIENT_ID =
  "786075768307-qfv51n3gdonfhvvotqk5cm4dv0pn8e3d.apps.googleusercontent.com";
const PICKER_SCOPE =
  "https://www.googleapis.com/auth/photospicker.mediaitems.readonly";
let webToken = null;

// Reads the token from the redirect URL of Google's implicit flow.
function tokenFromRedirect(url, now = Date.now()) {
  const params = new URLSearchParams(new URL(url).hash.slice(1));
  const token = params.get("access_token");
  if (!token) {
    throw new Error(params.get("error") ?? "Google sign-in returned no token");
  }
  const lifetime = Number(params.get("expires_in")) * 1000 || 3600000;
  // Renew a minute early rather than fail mid-pick.
  return { token, expires: now + lifetime - 60000 };
}

async function webAuthToken() {
  if (webToken && webToken.expires > Date.now()) {
    return webToken.token;
  }
  if (!WEB_CLIENT_ID) {
    throw new Error("Google Photos is not set up for this browser yet");
  }
  const url = new URL("https://accounts.google.com/o/oauth2/v2/auth");
  url.search = new URLSearchParams({
    client_id: WEB_CLIENT_ID,
    response_type: "token",
    redirect_uri: chrome.identity.getRedirectURL(),
    scope: PICKER_SCOPE,
  });
  webToken = tokenFromRedirect(
    await chrome.identity.launchWebAuthFlow({
      url: url.href,
      interactive: true,
    }),
  );
  return webToken.token;
}

async function authToken() {
  if (!chrome.identity?.launchWebAuthFlow) {
    throw new Error("This browser cannot sign in to Google Photos");
  }
  if (!chrome.identity.getAuthToken) {
    return webAuthToken();
  }
  const { token } = await chrome.identity.getAuthToken({ interactive: true });
  return token;
}

async function forgetToken(token) {
  webToken = null;
  await chrome.identity.removeCachedAuthToken?.({ token });
}

const exists = (lookup) =>
  lookup.then(
    () => true,
    () => false,
  );

// Shows Google's picker in a popup window, or a tab where there are no
// windows. Resolves to whether it is still open, and a way to close it.
async function showPicker(url) {
  if (chrome.windows) {
    const { id } = await chrome.windows.create({
      url,
      type: "popup",
      ...PICKER_WINDOW,
    });
    return {
      isOpen: () => exists(chrome.windows.get(id)),
      close: () => chrome.windows.remove(id).catch(() => {}),
    };
  }
  const { id } = await chrome.tabs.create({ url });
  return {
    isOpen: () => exists(chrome.tabs.get(id)),
    close: () => chrome.tabs.remove(id).catch(() => {}),
  };
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

// Resolves true once the picker reports a selection, or false if it closes
// or the session expires without one.
async function waitForPick(token, session, picker) {
  const interval = milliseconds(session.pollingConfig?.pollInterval, 5000);
  const deadline =
    Date.now() + milliseconds(session.pollingConfig?.timeoutIn, 600000);
  while (Date.now() < deadline) {
    // Check the picker first: it closes itself right after a selection.
    const open = await picker.isOpen();
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
  picker.close();
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
    // A cached token may have been revoked by Google since.
    await forgetToken(token);
    token = await authToken();
    session = await createSession(token);
  }
  try {
    const picker = await showPicker(`${session.pickerUri}/autoclose`);
    if (!(await waitForPick(token, session, picker))) {
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
  if (message.type === "openPhoneWindow") {
    openPhoneWindow().then(
      () => sendResponse({}),
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
