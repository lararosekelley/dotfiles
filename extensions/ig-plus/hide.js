// Applies the popup's settings to every Instagram tab: hides home feed posts
// below the stories tray, and the Reels tab. hide.css does the hiding.
(() => {
  const DEFAULTS = { hideFeed: true, hideReels: true };
  const INBOX = "/direct/inbox/";
  const root = document.documentElement;
  let settings = DEFAULTS;
  // Until the saved settings arrive, hide by default but never redirect.
  let loaded = false;

  // The feed is the outermost block of posts that leaves the stories tray out.
  // Hiding all of it also hides the loader at its end, so no more posts load.
  function feedOf(post) {
    const tray = document.querySelector('main [aria-label^="Story by"]');
    if (!tray) {
      // Posts sit together in a list, with the loader beside that list.
      return post.parentElement?.parentElement ?? post;
    }
    let feed = post;
    while (feed.parentElement && !feed.parentElement.contains(tray)) {
      feed = feed.parentElement;
    }
    return feed;
  }

  function update() {
    const home = location.pathname === "/";
    root.toggleAttribute("data-ig-plus-home", home);
    root.toggleAttribute("data-ig-plus-hide-feed", settings.hideFeed);
    root.toggleAttribute("data-ig-plus-hide-reels", settings.hideReels);
    if (loaded && settings.hideReels && location.pathname === "/reels/") {
      location.replace(INBOX);
      return;
    }
    if (home && settings.hideFeed) {
      const post = document.querySelector(
        "main article:not([data-ig-plus-feed] article)",
      );
      if (post) {
        feedOf(post).setAttribute("data-ig-plus-feed", "");
      }
    }
  }

  // Instagram navigates without reloading, so check again whenever it
  // changes the page, at most once a frame.
  let queued = false;
  new MutationObserver(() => {
    if (!queued) {
      queued = true;
      requestAnimationFrame(() => {
        queued = false;
        update();
      });
    }
  }).observe(root, { childList: true, subtree: true });

  chrome.storage.sync.get(DEFAULTS).then((stored) => {
    settings = stored;
    loaded = true;
    update();
  });
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === "sync") {
      for (const [key, { newValue }] of Object.entries(changes)) {
        settings = { ...settings, [key]: newValue ?? DEFAULTS[key] };
      }
      update();
    }
  });
  update();
})();
