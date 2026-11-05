// Runs in the page's main world so it can intercept Instagram's file inputs.
(() => {
  if (!matchMedia("(display-mode: standalone)").matches) {
    return;
  }

  const nativeClick = HTMLInputElement.prototype.click;
  const nativeShowPicker = HTMLInputElement.prototype.showPicker;
  let bypass = false;

  // Posts and stories open the same kind of file input, so only take over when
  // the click that led to it was on something about stories, such as the
  // Story menu item or the story bubble.
  const STORY_CLICK_WINDOW = 3000;
  let lastStoryClick = 0;

  const CONTROL =
    'a, button, label, [role="button"], [role="menuitem"], [role="link"]';

  // Looks only up to the clicked control, since a menu around it may list
  // both Post and Story.
  function mentionsStory(event) {
    for (const node of event.composedPath()) {
      if (!(node instanceof Element)) {
        return false;
      }
      const text = node.textContent.length <= 40 ? node.textContent : "";
      if (
        /\bstor(y|ies)\b/i.test(
          `${node.getAttribute("aria-label") ?? ""} ${text}`,
        )
      ) {
        return true;
      }
      if (node.matches(CONTROL)) {
        return false;
      }
    }
    return false;
  }

  function wantsCamera(element) {
    return (
      !bypass &&
      element instanceof HTMLInputElement &&
      element.type === "file" &&
      (!element.accept || element.accept.includes("image")) &&
      Date.now() - lastStoryClick < STORY_CLICK_WINDOW
    );
  }

  function openPicker(input) {
    bypass = true;
    try {
      nativeClick.call(input);
    } finally {
      bypass = false;
    }
  }

  // Clicks on connected inputs reach the listener below; detached inputs
  // never dispatch to the window, so catch them here.
  HTMLInputElement.prototype.click = function () {
    if (wantsCamera(this) && !this.isConnected) {
      showCamera(this);
      return;
    }
    return nativeClick.call(this);
  };

  HTMLInputElement.prototype.showPicker = function () {
    if (wantsCamera(this)) {
      showCamera(this);
      return;
    }
    return nativeShowPicker.call(this);
  };

  window.addEventListener(
    "click",
    (event) => {
      if (mentionsStory(event)) {
        lastStoryClick = Date.now();
      }
      if (wantsCamera(event.target)) {
        event.preventDefault();
        showCamera(event.target);
      }
    },
    true,
  );

  // Webcams are landscape, and Instagram crops anything that is not 9:16.
  const STORY = { width: 1080, height: 1920 };

  const TEXT_STYLES = [
    { fill: "#fff", shadow: true },
    { fill: "#000" },
    { fill: "#fff", box: "#000" },
    { fill: "#000", box: "#fff" },
  ];

  // One color is a solid fill; more make a diagonal gradient.
  const BACKGROUNDS = [
    ["#000000"],
    ["#ffffff"],
    ["#e1306c"],
    ["#405de6"],
    ["#fcaf45"],
    ["#2e8b57"],
    ["#833ab4", "#fd1d1d", "#fcb045"],
    ["#405de6", "#c13584"],
    ["#ff9a9e", "#fecfef"],
    ["#0f2027", "#2c5364"],
    ["#f7971e", "#ffd200"],
    ["#00c6ff", "#0072ff"],
  ];

  const BRUSH_COLORS = [
    "#ffffff",
    "#000000",
    "#ff3b30",
    "#ff9500",
    "#ffcc00",
    "#34c759",
    "#0a84ff",
    "#af52de",
    "#f08fb8",
  ];

  // Instagram's own fonts are not reachable from the page, so these use fonts
  // installed locally, falling back to generic families elsewhere.
  const FONTS = [
    { name: "Classic", font: (size) => `bold ${size}px system-ui, sans-serif` },
    {
      name: "Elegant",
      font: (size) => `italic ${size}px P052, Palatino, serif`,
    },
    { name: "Script", font: (size) => `${size}px Z003, cursive` },
  ];

  // Constructed stylesheets and DOM APIs avoid Instagram's CSP and Trusted
  // Types restrictions on inline styles and HTML strings.
  const styles = new CSSStyleSheet();
  styles.replaceSync(`
    /* Callie and Callie Light, from Callie's theme files. */
    :host {
      --background: #fbf5f8;
      --surface: #fffafc;
      --surface-alt: #f3e7ee;
      --border: #e0ccd7;
      --text: #2b1a26;
      --text-muted: #6b5562;
      --accent: #c2407a;
      --accent-text: #fffafc;
      --edge: #dcc8d3;
      --accent-edge: #8e2c5a;
      --danger: #c93c45;
      --danger-edge: #902b31;
      --danger-text: #fbf5f8;
      --done: #3f7b4a;
      --shadow: rgba(92, 42, 71, 0.18);
      --font: Nunito, system-ui, sans-serif;
      /* Quick, with a little overshoot when something arrives. */
      --bounce: cubic-bezier(0.34, 1.4, 0.64, 1);
    }
    @media (prefers-color-scheme: dark) {
      :host {
        --background: #1c1220;
        --surface: #261a2a;
        --surface-alt: #33243a;
        --border: #3d2c42;
        --text: #f6eef5;
        --text-muted: #c9b7c6;
        --accent: #f08fb8;
        --accent-text: #2e0f20;
        --edge: #140c17;
        --accent-edge: #a64b7a;
        --danger: #e66e6d;
        --danger-edge: #a44f4e;
        --danger-text: #1c1220;
        --done: #9dcca3;
        --shadow: rgba(0, 0, 0, 0.5);
      }
    }
    [hidden] {
      display: none !important;
    }
    .overlay {
      position: fixed;
      inset: 0;
      z-index: 2147483647;
      display: flex;
      flex-direction: column;
      background: var(--background);
      color: var(--text);
      font: 13px/1.4 var(--font);
      animation: arrive 200ms var(--bounce);
    }
    @keyframes arrive {
      from {
        opacity: 0;
        transform: scale(0.96);
      }
    }
    .stage {
      position: relative;
      flex: 1;
      min-height: 0;
      margin: 12px 12px 0;
      overflow: hidden;
      border-radius: 14px;
      background: #000;
    }
    video,
    canvas {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    video {
      transform: scaleX(-1);
    }
    canvas {
      touch-action: none;
    }
    .backdrop {
      object-fit: cover;
      filter: blur(30px) brightness(0.7);
      transform: scaleX(-1) scale(1.1);
    }
    .fill .backdrop {
      display: none;
    }
    .fill .main {
      object-fit: cover;
    }
    .message {
      padding: 8px 16px 0;
      color: var(--text-muted);
      font-weight: 600;
      text-align: center;
    }
    .controls {
      display: flex;
      flex-direction: column;
      gap: 8px;
      padding: 12px 16px 0;
    }
    .row {
      display: flex;
      gap: 8px;
      align-items: center;
      color: var(--text-muted);
      font-weight: 700;
    }
    input[type="range"] {
      flex: 1;
      accent-color: var(--accent);
    }
    textarea {
      padding: 8px 12px;
      border: 1px solid var(--border);
      border-radius: 11px;
      background: var(--surface);
      color: inherit;
      font: inherit;
      font-size: 14px;
      resize: none;
    }
    textarea::placeholder {
      color: var(--text-muted);
    }
    :focus-visible {
      outline: 2px solid var(--accent);
      outline-offset: 2px;
    }
    .picker {
      display: flex;
      gap: 4px;
      align-items: center;
      padding: 12px 8px 4px;
    }
    .swatches {
      display: flex;
      flex: 1;
      gap: 12px;
      overflow-x: auto;
      scrollbar-width: none;
      /* Room for the selected swatch's outline. */
      padding: 4px;
    }
    .arrow {
      flex: none;
      display: grid;
      place-items: center;
      width: 32px;
      height: 32px;
      padding: 0;
      background: transparent;
      box-shadow: none;
      color: var(--text-muted);
    }
    .arrow:disabled {
      opacity: 0.3;
    }
    .arrow svg {
      width: 18px;
      height: 18px;
      fill: none;
      stroke: currentColor;
      stroke-width: 1.8;
      stroke-linecap: round;
      stroke-linejoin: round;
    }
    .swatch {
      flex: none;
      width: 36px;
      height: 36px;
      padding: 0;
      border: 2px solid var(--border);
      border-radius: 50%;
      box-shadow: none;
    }
    .swatch.small {
      width: 28px;
      height: 28px;
    }
    .swatch.selected {
      outline: 2px solid var(--accent);
      outline-offset: 2px;
    }
    /* Like Callie's view switcher: plain until chosen, then a pink sticker. */
    .tools button {
      background: transparent;
      box-shadow: none;
      color: var(--text-muted);
    }
    .tools button[aria-pressed="true"] {
      background: var(--accent);
      box-shadow: 0 3px 0 var(--accent-edge);
      color: var(--accent-text);
      font-weight: 800;
    }
    .bar {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      justify-content: center;
      padding: 12px 16px 16px;
    }
    /* Pressable things are stickers, raised on an edge in a darker shade. */
    button {
      padding: 8px 14px;
      border: 0;
      border-radius: 11px;
      background: var(--surface-alt);
      box-shadow: 0 3px 0 var(--edge);
      color: var(--text);
      font: inherit;
      font-weight: 700;
      cursor: pointer;
      transition:
        transform 140ms,
        box-shadow 140ms;
    }
    button:active:not(:disabled) {
      transform: translateY(3px);
      box-shadow: 0 0 0 var(--edge);
    }
    button.primary {
      background: var(--accent);
      box-shadow: 0 3px 0 var(--accent-edge);
      color: var(--accent-text);
      font-weight: 800;
    }
    button:disabled {
      opacity: 0.5;
      cursor: default;
    }
    /* Like Callie's DangerButton: a red label, filled red while it waits for
       the click that confirms. */
    button.destructive {
      color: var(--danger);
    }
    button.destructive.armed {
      background: var(--danger);
      box-shadow: 0 3px 0 var(--danger-edge);
      color: var(--danger-text);
      font-weight: 800;
    }
    /* Like the git-stk tour's checkboxes: a ring that fills when checked. */
    .check {
      position: relative;
      display: inline-flex;
      gap: 8px;
      align-items: center;
      padding: 8px 4px;
      color: var(--text-muted);
      font-weight: 700;
      cursor: pointer;
    }
    .check input {
      position: absolute;
      opacity: 0;
      pointer-events: none;
    }
    .check .box {
      display: grid;
      place-items: center;
      width: 18px;
      height: 18px;
      border: 2px solid var(--text-muted);
      border-radius: 50%;
      box-sizing: border-box;
    }
    .check svg {
      width: 14px;
      height: 14px;
      fill: none;
      stroke: var(--background);
      stroke-width: 2.2;
      stroke-linecap: round;
      stroke-linejoin: round;
      visibility: hidden;
    }
    .check input:checked + .box {
      border-color: var(--done);
      background: var(--done);
    }
    .check input:checked + .box svg {
      visibility: visible;
    }
    .check input:checked ~ span {
      color: var(--text);
    }
    .check input:focus-visible + .box {
      outline: 2px solid var(--accent);
      outline-offset: 2px;
    }
    .floating {
      position: fixed;
      top: 12px;
      left: 12px;
      z-index: 2147483647;
      display: flex;
      gap: 8px;
      align-items: center;
      font: 13px/1.4 var(--font);
      animation: arrive 200ms var(--bounce);
    }
    .floating button {
      box-shadow:
        0 3px 0 var(--edge),
        0 14px 36px var(--shadow);
    }
    .badge {
      padding: 4px 10px;
      border-radius: 999px;
      background: var(--done);
      color: var(--background);
      font-weight: 800;
    }
    .notice {
      position: fixed;
      top: 12px;
      left: 50%;
      z-index: 2147483647;
      width: min(360px, calc(100vw - 24px));
      padding: 12px 16px;
      border: 1px solid var(--border);
      border-radius: 16px;
      background: var(--surface);
      box-shadow: 0 14px 36px var(--shadow);
      color: var(--text);
      font: 600 13px/1.4 var(--font);
      transform: translateX(-50%);
      cursor: pointer;
    }
    .notice.warning {
      border-color: var(--danger);
    }
    @media (prefers-reduced-motion: reduce) {
      .overlay,
      .floating {
        animation: none;
      }
      button {
        transition: none;
      }
    }
  `);

  function element(tag, properties = {}) {
    return Object.assign(document.createElement(tag), properties);
  }

  // Built as DOM rather than a CSS image, which Instagram's CSP could block.
  const ICONS = {
    left: "M10 3.5 5.5 8l4.5 4.5",
    right: "M6 3.5 10.5 8 6 12.5",
    check: "M4 8.5 6.8 11 12 5.5",
  };

  function icon(name) {
    const namespace = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(namespace, "svg");
    svg.setAttribute("viewBox", "0 0 16 16");
    const path = document.createElementNS(namespace, "path");
    path.setAttribute("d", ICONS[name]);
    svg.append(path);
    return svg;
  }

  // Like Callie's DangerButton: the first click arms it, and a second within
  // a few seconds confirms.
  function confirmingButton(label, armedLabel, onConfirm) {
    const button = element("button", {
      className: "destructive",
      textContent: label,
    });
    let disarm;
    button.onclick = () => {
      if (button.classList.contains("armed")) {
        clearTimeout(disarm);
        onConfirm();
        return;
      }
      button.classList.add("armed");
      button.textContent = armedLabel;
      disarm = setTimeout(() => {
        button.classList.remove("armed");
        button.textContent = label;
      }, 4000);
    };
    return button;
  }

  function fitScale(image, fit) {
    return (fit === "cover" ? Math.max : Math.min)(
      STORY.width / image.width,
      STORY.height / image.height,
    );
  }

  function drawScaled(context, image, scale, x = 0, y = 0) {
    const width = image.width * scale;
    const height = image.height * scale;
    context.drawImage(
      image,
      (STORY.width - width) / 2 + x,
      (STORY.height - height) / 2 + y,
      width,
      height,
    );
  }

  // Draws the photo over a blurred copy of itself, so any part of the frame it
  // does not cover still looks intentional.
  function drawPhoto(context, { image, zoom, x, y }) {
    context.save();
    context.filter = "blur(60px) brightness(0.7)";
    drawScaled(context, image, fitScale(image, "cover") * 1.1);
    context.restore();
    drawScaled(context, image, fitScale(image, "contain") * zoom, x, y);
  }

  function captureFrame(video) {
    const canvas = element("canvas", {
      width: video.videoWidth,
      height: video.videoHeight,
    });
    const context = canvas.getContext("2d");
    // Match the mirrored preview.
    context.translate(canvas.width, 0);
    context.scale(-1, 1);
    context.drawImage(video, 0, 0);
    return canvas;
  }

  function cssBackground(colors) {
    return colors.length === 1
      ? colors[0]
      : `linear-gradient(135deg, ${colors.join(", ")})`;
  }

  function drawBackground(context, colors) {
    if (colors.length === 1) {
      context.fillStyle = colors[0];
    } else {
      const gradient = context.createLinearGradient(
        0,
        0,
        STORY.width,
        STORY.height,
      );
      colors.forEach((color, index) =>
        gradient.addColorStop(index / (colors.length - 1), color),
      );
      context.fillStyle = gradient;
    }
    context.fillRect(0, 0, STORY.width, STORY.height);
  }

  function wrapLines(context, value, maxWidth) {
    return value.split("\n").flatMap((paragraph) => {
      const lines = [];
      let line = "";
      for (const word of paragraph.split(" ")) {
        const candidate = line ? `${line} ${word}` : word;
        if (line && context.measureText(candidate).width > maxWidth) {
          lines.push(line);
          line = word;
        } else {
          line = candidate;
        }
      }
      return [...lines, line];
    });
  }

  function drawText(context, { value, x, y, size, style, font }) {
    if (!value.trim()) {
      return;
    }
    const { fill, box, shadow } = TEXT_STYLES[style];
    const lineHeight = size * 1.25;
    context.save();
    context.font = FONTS[font].font(size);
    context.textAlign = "center";
    context.textBaseline = "middle";
    const lines = wrapLines(context, value, STORY.width * 0.85);
    const top = y - (lineHeight * (lines.length - 1)) / 2;
    lines.forEach((line, index) => {
      const lineY = top + index * lineHeight;
      if (box && line) {
        const width = context.measureText(line).width + size * 0.6;
        context.fillStyle = box;
        context.beginPath();
        context.roundRect(
          x - width / 2,
          lineY - lineHeight / 2,
          width,
          lineHeight,
          size * 0.25,
        );
        context.fill();
      }
      if (shadow) {
        context.shadowColor = "rgba(0, 0, 0, 0.6)";
        context.shadowBlur = size * 0.2;
      }
      context.fillStyle = fill;
      context.fillText(line, x, lineY);
      context.shadowColor = "transparent";
    });
    context.restore();
  }

  function drawStrokes(context, strokes) {
    context.save();
    context.lineCap = "round";
    context.lineJoin = "round";
    for (const { color, size, points } of strokes) {
      context.strokeStyle = color;
      context.lineWidth = size;
      context.beginPath();
      context.moveTo(points[0].x, points[0].y);
      // A single point still draws a dot thanks to the round cap.
      for (const point of points) {
        context.lineTo(point.x, point.y);
      }
      context.stroke();
    }
    context.restore();
  }

  // Maps a pointer position onto the story canvas, which is letterboxed by
  // object-fit.
  function storyPoint(canvas, event) {
    const rect = canvas.getBoundingClientRect();
    const scale = Math.min(
      rect.width / STORY.width,
      rect.height / STORY.height,
    );
    return {
      x:
        (event.clientX - rect.left - (rect.width - STORY.width * scale) / 2) /
        scale,
      y:
        (event.clientY - rect.top - (rect.height - STORY.height * scale) / 2) /
        scale,
    };
  }

  // Mirrors how a file input's accept attribute filters the picker.
  function accepts(input, file) {
    const tokens = input.accept
      .split(",")
      .map((token) => token.trim().toLowerCase())
      .filter(Boolean);
    const name = file.name.toLowerCase();
    const type = file.type.toLowerCase();
    return (
      tokens.length === 0 ||
      tokens.some((token) =>
        token.startsWith(".")
          ? name.endsWith(token)
          : token.endsWith("/*")
            ? type.startsWith(token.slice(0, -1))
            : type === token,
      )
    );
  }

  function attach(input, file) {
    const transfer = new DataTransfer();
    transfer.items.add(file);
    input.files = transfer.files;
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }

  let discardHost;

  // Instagram's mobile web composer offers no way out other than sharing, so
  // add one that returns to the feed. It goes away once Instagram navigates
  // home itself, as it does after sharing.
  function showDiscard(closeFriends) {
    discardHost?.remove();
    const host = element("div");
    const root = host.attachShadow({ mode: "closed" });
    root.adoptedStyleSheets = [styles];
    const floating = element("div", { className: "floating" });
    floating.append(
      confirmingButton("Discard", "Confirm discard", () =>
        location.assign("/"),
      ),
    );
    if (closeFriends) {
      floating.append(
        element("span", { className: "badge", textContent: "Close friends" }),
      );
    }
    root.append(floating);
    document.documentElement.append(host);
    discardHost = host;

    const removeOnHome = (event) => {
      if (new URL(event.destination.url).pathname === "/") {
        host.remove();
        navigation.removeEventListener("navigate", removeOnHome);
      }
    };
    navigation.addEventListener("navigate", removeOnHome);
  }

  const SHARE_NOTICES = {
    "close-friends": "Shared to close friends.",
    public:
      "Instagram did not apply close friends, so this story went to everyone.",
    unknown:
      "Instagram did not confirm close friends. Check the story's ring before anyone sees it.",
    blocked: "Not shared: close friends could not be applied.",
  };

  // audience.js reports how a close friends share went.
  window.addEventListener("ig-plus:shared", (event) => {
    const { status } = event.detail;
    const host = element("div");
    const root = host.attachShadow({ mode: "closed" });
    root.adoptedStyleSheets = [styles];
    const notice = element("div", {
      className: status === "close-friends" ? "notice" : "notice warning",
      textContent: SHARE_NOTICES[status],
      onclick: () => host.remove(),
    });
    root.append(notice);
    document.documentElement.append(host);
    if (status === "close-friends") {
      setTimeout(() => host.remove(), 5000);
    }
  });

  // This script runs in the page's world and cannot reach the extension, so
  // bridge.js answers these requests: "googlePhoto" resolves to the picked
  // File or null, and "uiFont" to the bytes of Callie's Nunito.
  function askExtension(request) {
    const id = crypto.randomUUID();
    return new Promise((resolve, reject) => {
      const onMessage = (event) => {
        const { data } = event;
        if (
          event.source !== window ||
          data?.type !== "ig-plus:answer" ||
          data.id !== id
        ) {
          return;
        }
        window.removeEventListener("message", onMessage);
        if (data.error) {
          reject(new Error(data.error));
        } else {
          resolve(data.result);
        }
      };
      window.addEventListener("message", onMessage);
      window.postMessage({ type: "ig-plus:ask", id, request }, location.origin);
    });
  }

  let fontLoaded = false;
  // Instagram's CSP may block fonts the page loads, but not ones built from
  // bytes. Without the font, the styles fall back to the system's.
  async function loadFont() {
    if (fontLoaded) {
      return;
    }
    fontLoaded = true;
    try {
      const font = new FontFace("Nunito", await askExtension("uiFont"), {
        weight: "200 1000",
      });
      document.fonts.add(await font.load());
    } catch (error) {
      console.warn("IG Plus could not load Nunito:", error);
    }
  }

  async function showCamera(input) {
    loadFont();
    const host = element("div");
    const root = host.attachShadow({ mode: "closed" });
    root.adoptedStyleSheets = [styles];

    const videoProperties = { autoplay: true, muted: true, playsInline: true };
    const backdrop = element("video", {
      ...videoProperties,
      className: "backdrop",
    });
    const video = element("video", { ...videoProperties, className: "main" });
    const review = element("canvas", { ...STORY, hidden: true });
    const stage = element("div", { className: "stage" });
    stage.append(backdrop, video, review);

    const message = element("div", {
      className: "message",
      textContent: "Starting camera...",
    });
    const fileInput = element("input", {
      type: "file",
      accept: "image/*,video/*",
      hidden: true,
    });

    const swatchList = element("div", { className: "swatches" });
    const swatchButtons = BACKGROUNDS.map((background) => {
      const swatch = element("button", { className: "swatch" });
      swatch.style.background = cssBackground(background);
      swatch.onclick = () => pickBackground(swatch, background);
      return swatch;
    });
    swatchList.append(...swatchButtons);
    const previous = element("button", {
      className: "arrow",
      ariaLabel: "Previous colors",
    });
    previous.append(icon("left"));
    const next = element("button", {
      className: "arrow",
      ariaLabel: "More colors",
    });
    next.append(icon("right"));
    const swatches = element("div", { className: "picker", hidden: true });
    swatches.append(previous, swatchList, next);

    const zoomInput = element("input", {
      type: "range",
      min: 0.5,
      max: 5,
      step: 0.01,
      value: 1,
    });
    const photoRow = element("div", { className: "row" });
    photoRow.append(element("span", { textContent: "Zoom" }), zoomInput);

    const toolButtons = {
      photo: element("button", { textContent: "Photo" }),
      text: element("button", { textContent: "Text" }),
      brush: element("button", { textContent: "Brush" }),
    };
    const toolRow = element("div", { className: "row tools" });
    toolRow.append(...Object.values(toolButtons));

    const brushSwatches = element("div", { className: "row" });
    const brushButtons = BRUSH_COLORS.map((color) => {
      const swatch = element("button", { className: "swatch small" });
      swatch.style.background = color;
      swatch.onclick = () => pickBrush(color);
      return swatch;
    });
    brushSwatches.append(...brushButtons);
    const brushSizeInput = element("input", {
      type: "range",
      min: 4,
      max: 60,
      value: 16,
    });
    const undo = element("button", { textContent: "Undo" });
    const clear = element("button", { textContent: "Clear" });
    const brushSizeRow = element("div", { className: "row" });
    brushSizeRow.append(
      element("span", { textContent: "Size" }),
      brushSizeInput,
      undo,
      clear,
    );

    const textInput = element("textarea", {
      rows: 2,
      placeholder: "Add text, then drag on the image to place it",
    });
    const sizeInput = element("input", {
      type: "range",
      min: 40,
      max: 180,
      value: 80,
    });
    const fontButton = element("button", { textContent: FONTS[0].name });
    const styleButton = element("button", { textContent: "Style" });
    const sizeRow = element("div", { className: "row" });
    sizeRow.append(
      element("span", { textContent: "Text" }),
      sizeInput,
      fontButton,
      styleButton,
    );
    const controls = element("div", { className: "controls", hidden: true });
    // Each tool shows only its own controls.
    const toolControls = {
      photo: [photoRow],
      text: [textInput, sizeRow],
      brush: [brushSwatches, brushSizeRow],
    };
    controls.append(
      toolRow,
      photoRow,
      textInput,
      sizeRow,
      brushSwatches,
      brushSizeRow,
    );

    const cancel = element("button", {
      className: "destructive",
      textContent: "Cancel",
    });
    const choose = element("button", { textContent: "Choose file" });
    const googlePhotos = element("button", { textContent: "Google Photos" });
    const colors = element("button", { textContent: "Colors" });
    const framing = element("button", { textContent: "Crop" });
    const take = element("button", {
      className: "primary",
      textContent: "Take photo",
      disabled: true,
    });
    const cameraBar = element("div", { className: "bar" });
    cameraBar.append(cancel, choose, googlePhotos, colors, framing, take);

    const back = element("button");
    const done = element("button", {
      className: "primary",
      textContent: "Done",
    });
    // Moves to whichever bar is showing, since videos skip the editor.
    const audienceInput = element("input", { type: "checkbox" });
    const audienceBox = element("span", { className: "box" });
    audienceBox.append(icon("check"));
    const audienceToggle = element("label", { className: "check" });
    audienceToggle.append(
      audienceInput,
      audienceBox,
      element("span", { textContent: "Close friends" }),
    );
    cameraBar.insertBefore(audienceToggle, take);
    const reviewBar = element("div", { className: "bar", hidden: true });
    reviewBar.append(back, done);

    const overlay = element("div", { className: "overlay" });
    overlay.append(stage, message, swatches, controls, cameraBar, reviewBar);
    root.append(overlay, fileInput);
    document.documentElement.append(host);

    let stream;
    // Either { colors } or { image, zoom, x, y }.
    let base;
    let tool = "text";
    let lastPoint;
    const brush = { color: BRUSH_COLORS[0], size: 16 };
    const strokes = [];
    const text = {
      value: "",
      x: STORY.width / 2,
      y: STORY.height / 2,
      size: 80,
      style: 0,
      font: 0,
    };

    const render = () => {
      const context = review.getContext("2d");
      if (base.colors) {
        drawBackground(context, base.colors);
      } else {
        drawPhoto(context, base);
      }
      drawStrokes(context, strokes);
      drawText(context, text);
    };
    const showMessage = (value) => {
      message.textContent = value;
      message.hidden = !value;
    };
    // "camera" shows the live view; "photo" and "colors" are the editor.
    const setMode = (mode, backLabel = "Back") => {
      const editing = mode !== "camera";
      backdrop.hidden = video.hidden = cameraBar.hidden = editing;
      review.hidden = controls.hidden = reviewBar.hidden = !editing;
      message.hidden = editing || !message.textContent;
      swatches.hidden = mode !== "colors";
      toolButtons.photo.hidden = mode !== "photo";
      back.textContent = backLabel;
      const bar = editing ? reviewBar : cameraBar;
      bar.insertBefore(audienceToggle, bar.lastElementChild);
    };
    const setTool = (name) => {
      tool = name;
      for (const [key, button] of Object.entries(toolButtons)) {
        button.ariaPressed = String(key === name);
        for (const control of toolControls[key]) {
          control.hidden = key !== name;
        }
      }
    };
    const pickBrush = (color) => {
      brush.color = color;
      brushButtons.forEach((button, index) =>
        button.classList.toggle("selected", BRUSH_COLORS[index] === color),
      );
    };
    pickBrush(brush.color);
    const setZoom = (zoom) => {
      base.zoom = Math.min(
        Math.max(zoom, Number(zoomInput.min)),
        Number(zoomInput.max),
      );
      zoomInput.value = base.zoom;
      render();
    };
    const editPhoto = (image, fill, backLabel) => {
      const fillZoom = fitScale(image, "cover") / fitScale(image, "contain");
      zoomInput.max = Math.max(5, fillZoom);
      base = { image, zoom: 1, x: 0, y: 0 };
      strokes.length = 0;
      setZoom(fill ? fillZoom : 1);
      setTool("photo");
      setMode("photo", backLabel);
    };
    const pickBackground = (swatch, background) => {
      swatchButtons.forEach((button) =>
        button.classList.toggle("selected", button === swatch),
      );
      base = { colors: background };
      render();
    };
    const close = () => {
      stream?.getTracks().forEach((track) => track.stop());
      host.remove();
    };
    const handOff = (file) => {
      close();
      attach(input, file);
      const closeFriends = audienceInput.checked;
      window.dispatchEvent(
        new CustomEvent("ig-plus:handoff", { detail: { closeFriends } }),
      );
      showDiscard(closeFriends);
    };

    const openFile = async (file) => {
      if (!file.type.startsWith("image/")) {
        // Instagram shows a blank composer for files its input does not take.
        if (accepts(input, file)) {
          handOff(file);
        } else {
          showMessage(
            `Instagram's web composer does not take ${file.type || file.name} for stories. It takes: ${input.accept}`,
          );
        }
        return;
      }
      try {
        editPhoto(await createImageBitmap(file), false, "Back");
      } catch (error) {
        showMessage(`Could not open ${file.name}: ${error.message}`);
      }
    };

    cancel.onclick = close;
    choose.onclick = () => openPicker(fileInput);
    fileInput.onchange = () => {
      const [file] = fileInput.files;
      fileInput.value = "";
      if (file) {
        openFile(file);
      }
    };
    googlePhotos.onclick = async () => {
      googlePhotos.disabled = true;
      showMessage("Pick a photo in the Google Photos window");
      try {
        const file = await askExtension("googlePhoto");
        showMessage("");
        if (file && host.isConnected) {
          openFile(file);
        }
      } catch (error) {
        showMessage(`Google Photos failed: ${error.message}`);
      } finally {
        googlePhotos.disabled = false;
      }
    };
    framing.onclick = () => {
      const fill = stage.classList.toggle("fill");
      framing.textContent = fill ? "Whole" : "Crop";
    };
    colors.onclick = () => {
      const selected =
        swatchButtons.find((swatch) => swatch.classList.contains("selected")) ??
        swatchButtons[0];
      strokes.length = 0;
      pickBackground(selected, BACKGROUNDS[swatchButtons.indexOf(selected)]);
      setTool("text");
      setMode("colors");
    };
    take.onclick = () =>
      editPhoto(
        captureFrame(video),
        stage.classList.contains("fill"),
        "Retake",
      );
    back.onclick = () => setMode("camera");
    done.onclick = () =>
      review.toBlob(
        (blob) =>
          handOff(
            new File([blob], `story-${Date.now()}.jpg`, { type: "image/jpeg" }),
          ),
        "image/jpeg",
        0.92,
      );

    const updateArrows = () => {
      previous.disabled = swatchList.scrollLeft <= 0;
      next.disabled =
        swatchList.scrollLeft + swatchList.clientWidth >=
        swatchList.scrollWidth - 1;
    };
    const scrollSwatches = (direction) =>
      swatchList.scrollBy({
        left: direction * swatchList.clientWidth * 0.8,
        behavior: "smooth",
      });
    previous.onclick = () => scrollSwatches(-1);
    next.onclick = () => scrollSwatches(1);
    swatchList.onscroll = updateArrows;
    new ResizeObserver(updateArrows).observe(swatchList);

    zoomInput.oninput = () => setZoom(Number(zoomInput.value));
    for (const [name, button] of Object.entries(toolButtons)) {
      button.onclick = () => setTool(name);
    }
    brushSizeInput.oninput = () => {
      brush.size = Number(brushSizeInput.value);
    };
    undo.onclick = () => {
      strokes.pop();
      render();
    };
    clear.onclick = () => {
      strokes.length = 0;
      render();
    };

    // Keep Instagram's keyboard shortcuts from reacting to typing.
    textInput.addEventListener("keydown", (event) => event.stopPropagation());
    textInput.oninput = () => {
      text.value = textInput.value;
      render();
    };
    sizeInput.oninput = () => {
      text.size = Number(sizeInput.value);
      render();
    };
    fontButton.onclick = () => {
      text.font = (text.font + 1) % FONTS.length;
      fontButton.textContent = FONTS[text.font].name;
      render();
    };
    styleButton.onclick = () => {
      text.style = (text.style + 1) % TEXT_STYLES.length;
      render();
    };

    const drag = (point) => {
      if (tool === "brush") {
        strokes.at(-1).points.push(point);
      } else if (tool === "photo" && base.image) {
        base.x += point.x - lastPoint.x;
        base.y += point.y - lastPoint.y;
      } else {
        Object.assign(text, point);
      }
      lastPoint = point;
      render();
    };
    review.addEventListener("pointerdown", (event) => {
      review.setPointerCapture(event.pointerId);
      lastPoint = storyPoint(review, event);
      if (tool === "brush") {
        strokes.push({ ...brush, points: [] });
      }
      drag(lastPoint);
    });
    review.addEventListener("pointermove", (event) => {
      if (review.hasPointerCapture(event.pointerId)) {
        drag(storyPoint(review, event));
      }
    });
    review.addEventListener(
      "wheel",
      (event) => {
        if (base.image) {
          event.preventDefault();
          setZoom(base.zoom * Math.exp(-event.deltaY * 0.002));
        }
      },
      { passive: false },
    );

    try {
      stream = await navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 1920 }, height: { ideal: 1080 } },
        audio: false,
      });
    } catch (error) {
      showMessage(`Camera unavailable: ${error.message}`);
      return;
    }
    if (!host.isConnected) {
      close();
      return;
    }
    video.srcObject = stream;
    backdrop.srcObject = stream;
    showMessage("");
    take.disabled = false;
  }
})();
