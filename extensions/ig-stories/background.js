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
