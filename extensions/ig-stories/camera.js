// Runs in the page's main world so it can intercept Instagram's file inputs.
(() => {
  if (!matchMedia("(display-mode: standalone)").matches) {
    return;
  }

  const nativeClick = HTMLInputElement.prototype.click;
  const nativeShowPicker = HTMLInputElement.prototype.showPicker;
  let bypass = false;

  function wantsCamera(element) {
    return (
      !bypass &&
      element instanceof HTMLInputElement &&
      element.type === "file" &&
      (!element.accept || element.accept.includes("image"))
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

  // Instagram's own fonts are not reachable from the page, so these use fonts
  // installed locally, falling back to generic families elsewhere.
  const FONTS = [
    { name: "Classic", font: (size) => `bold ${size}px system-ui, sans-serif` },
    { name: "Elegant", font: (size) => `italic ${size}px P052, Palatino, serif` },
    { name: "Script", font: (size) => `${size}px Z003, cursive` },
  ];

  // Constructed stylesheets and DOM APIs avoid Instagram's CSP and Trusted
  // Types restrictions on inline styles and HTML strings.
  const styles = new CSSStyleSheet();
  styles.replaceSync(`
    [hidden] {
      display: none !important;
    }
    .overlay {
      position: fixed;
      inset: 0;
      z-index: 2147483647;
      display: flex;
      flex-direction: column;
      background: #000;
      color: #fff;
      font: 15px system-ui, sans-serif;
    }
    .stage {
      position: relative;
      flex: 1;
      min-height: 0;
      overflow: hidden;
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
      padding: 8px 16px;
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
    }
    input[type="range"] {
      flex: 1;
    }
    textarea {
      padding: 8px;
      border: 0;
      border-radius: 8px;
      background: #222;
      color: inherit;
      font: inherit;
      resize: none;
    }
    .bar {
      display: flex;
      gap: 8px;
      justify-content: center;
      padding: 16px;
    }
    button {
      padding: 10px 16px;
      border: 0;
      border-radius: 8px;
      background: #333;
      color: inherit;
      font: inherit;
    }
    button.primary {
      background: #fff;
      color: #000;
    }
    button:disabled {
      opacity: 0.5;
    }
    .discard {
      position: fixed;
      top: 12px;
      left: 12px;
      z-index: 2147483647;
      background: rgba(0, 0, 0, 0.6);
    }
  `);

  function element(tag, properties = {}) {
    return Object.assign(document.createElement(tag), properties);
  }

  function drawCentered(context, video, fit, scale = 1) {
    const ratios = [
      STORY.width / video.videoWidth,
      STORY.height / video.videoHeight,
    ];
    const factor = (fit === "cover" ? Math.max : Math.min)(...ratios) * scale;
    const width = video.videoWidth * factor;
    const height = video.videoHeight * factor;
    context.drawImage(
      video,
      (STORY.width - width) / 2,
      (STORY.height - height) / 2,
      width,
      height,
    );
  }

  function capture(video, fill) {
    const canvas = element("canvas", STORY);
    const context = canvas.getContext("2d");
    // Match the mirrored preview.
    context.translate(STORY.width, 0);
    context.scale(-1, 1);
    if (fill) {
      drawCentered(context, video, "cover");
    } else {
      context.filter = "blur(60px) brightness(0.7)";
      drawCentered(context, video, "cover", 1.1);
      context.filter = "none";
      drawCentered(context, video, "contain");
    }
    return canvas;
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

  function attach(input, blob) {
    const transfer = new DataTransfer();
    transfer.items.add(
      new File([blob], `webcam-${Date.now()}.jpg`, { type: "image/jpeg" }),
    );
    input.files = transfer.files;
    input.dispatchEvent(new Event("input", { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }

  let discardHost;

  // Instagram's mobile web composer offers no way out other than sharing, so
  // add one that returns to the feed. It goes away once Instagram navigates
  // home itself, as it does after sharing.
  function showDiscard() {
    discardHost?.remove();
    const host = element("div");
    const root = host.attachShadow({ mode: "closed" });
    root.adoptedStyleSheets = [styles];
    root.append(
      element("button", {
        className: "discard",
        textContent: "Discard",
        onclick: () => location.assign("/"),
      }),
    );
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

  async function showCamera(input) {
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

    const textInput = element("textarea", {
      rows: 2,
      placeholder: "Add text, then drag on the photo to place it",
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
    sizeRow.append(sizeInput, fontButton, styleButton);
    const controls = element("div", { className: "controls", hidden: true });
    controls.append(textInput, sizeRow);

    const cancel = element("button", { textContent: "Cancel" });
    const choose = element("button", { textContent: "Choose file" });
    const framing = element("button", { textContent: "Crop" });
    const take = element("button", {
      className: "primary",
      textContent: "Take photo",
      disabled: true,
    });
    const cameraBar = element("div", { className: "bar" });
    cameraBar.append(cancel, choose, framing, take);

    const retake = element("button", { textContent: "Retake" });
    const use = element("button", {
      className: "primary",
      textContent: "Use photo",
    });
    const reviewBar = element("div", { className: "bar", hidden: true });
    reviewBar.append(retake, use);

    const overlay = element("div", { className: "overlay" });
    overlay.append(stage, message, controls, cameraBar, reviewBar);
    root.append(overlay);
    document.documentElement.append(host);

    let stream;
    let photo;
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
      context.drawImage(photo, 0, 0);
      drawText(context, text);
    };
    const setReviewing = (reviewing) => {
      backdrop.hidden = video.hidden = cameraBar.hidden = reviewing;
      review.hidden = controls.hidden = reviewBar.hidden = !reviewing;
    };
    const close = () => {
      stream?.getTracks().forEach((track) => track.stop());
      host.remove();
    };

    cancel.onclick = close;
    choose.onclick = () => {
      close();
      openPicker(input);
    };
    framing.onclick = () => {
      const fill = stage.classList.toggle("fill");
      framing.textContent = fill ? "Whole" : "Crop";
    };
    take.onclick = () => {
      photo = capture(video, stage.classList.contains("fill"));
      render();
      setReviewing(true);
    };
    retake.onclick = () => setReviewing(false);
    use.onclick = () =>
      review.toBlob(
        (blob) => {
          close();
          attach(input, blob);
          showDiscard();
        },
        "image/jpeg",
        0.92,
      );

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

    const moveText = (event) => {
      Object.assign(text, storyPoint(review, event));
      render();
    };
    review.addEventListener("pointerdown", (event) => {
      review.setPointerCapture(event.pointerId);
      moveText(event);
    });
    review.addEventListener("pointermove", (event) => {
      if (review.hasPointerCapture(event.pointerId)) {
        moveText(event);
      }
    });

    try {
      stream = await navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 1920 }, height: { ideal: 1080 } },
        audio: false,
      });
    } catch (error) {
      message.textContent = `Camera unavailable: ${error.message}`;
      return;
    }
    if (!host.isConnected) {
      close();
      return;
    }
    video.srcObject = stream;
    backdrop.srcObject = stream;
    message.remove();
    take.disabled = false;
  }
})();
