// Runs in the page's main world so it can amend Instagram's own request when a
// story should go to close friends only. Instagram's mobile web composer has
// no audience setting, but the endpoint it shares through accepts the one the
// phone apps send.
(() => {
  if (!matchMedia("(display-mode: standalone)").matches) {
    return;
  }

  const SHARE_URL = /\/api\/v1\/media\/configure_to_story\//;

  // camera.js says whether the story it hands off is for close friends.
  let closeFriends = false;
  window.addEventListener("ig-stories:handoff", (event) => {
    closeFriends = event.detail.closeFriends;
  });

  function amend(body) {
    const params = new URLSearchParams(
      body instanceof URLSearchParams || typeof body === "string" ? body : "",
    );
    if (!params.has("upload_id")) {
      return null;
    }
    params.set("audience", "besties");
    // The phone apps never cross-post close friends stories to Facebook.
    params.set("share_to_facebook", "false");
    params.delete("share_to_fb_destination_id");
    params.delete("share_to_fb_destination_type");
    return typeof body === "string" ? params.toString() : params;
  }

  // Reports whether Instagram applied the audience, so a story that went to
  // everyone is not mistaken for a close friends one.
  function report(response) {
    let media;
    try {
      const data =
        typeof response === "string" ? JSON.parse(response) : response;
      media = data?.media;
    } catch {}
    let status = "unknown";
    if (media) {
      status = media.audience === "besties" ? "close-friends" : "public";
    }
    window.dispatchEvent(
      new CustomEvent("ig-stories:shared", { detail: { status } }),
    );
  }

  // Returns the amended body, null to leave the request alone, or "block"
  // when a close friends story cannot be amended and must not go out.
  function takeAmendment(method, url, body) {
    if (
      !closeFriends ||
      method.toUpperCase() !== "POST" ||
      !SHARE_URL.test(url)
    ) {
      return null;
    }
    closeFriends = false;
    const amended = amend(body);
    if (!amended) {
      console.warn("IG Stories could not read the share request:", body);
      window.dispatchEvent(
        new CustomEvent("ig-stories:shared", { detail: { status: "blocked" } }),
      );
      return "block";
    }
    return amended;
  }

  const nativeFetch = window.fetch;
  window.fetch = function (resource, options = {}) {
    const request = resource instanceof Request ? resource : null;
    const url = request ? request.url : String(resource);
    const method = options.method ?? request?.method ?? "GET";
    const amended = takeAmendment(method, url, options.body);
    if (!amended) {
      return nativeFetch.apply(this, arguments);
    }
    if (amended === "block") {
      return Promise.reject(
        new TypeError("Close friends could not be applied"),
      );
    }
    const response = nativeFetch.call(this, resource, {
      ...options,
      body: amended,
    });
    response.then((result) => result.clone().text()).then(report, () => {});
    return response;
  };

  const nativeOpen = XMLHttpRequest.prototype.open;
  const nativeSend = XMLHttpRequest.prototype.send;
  const requests = new WeakMap();
  XMLHttpRequest.prototype.open = function (method, url) {
    requests.set(this, { method, url: String(url) });
    return nativeOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function (body) {
    const { method = "GET", url = "" } = requests.get(this) ?? {};
    const amended = takeAmendment(method, url, body);
    if (!amended) {
      return nativeSend.apply(this, arguments);
    }
    if (amended === "block") {
      this.abort();
      return;
    }
    this.addEventListener("load", () =>
      report(this.responseType === "json" ? this.response : this.responseText),
    );
    return nativeSend.call(this, amended);
  };
})();
