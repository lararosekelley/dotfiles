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
    .swatches {
      display: flex;
      gap: 8px;
      overflow-x: auto;
      padding: 12px 16px 0;
    }
    .swatch {
      flex: none;
      width: 36px;
      height: 36px;
      padding: 0;
      border: 2px solid #555;
      border-radius: 50%;
    }
    .swatch.selected {
      border-color: #fff;
    }
    .bar {
      display: flex;
      flex-wrap: wrap;
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

  // Resolves to the picked File, or null if nothing was picked. bridge.js
  // passes the request on to background.js.
  function pickGooglePhoto() {
    const id = crypto.randomUUID();
    return new Promise((resolve, reject) => {
      const onMessage = (event) => {
        const { data } = event;
        if (
          event.source !== window ||
          data?.type !== "ig-stories:google-photo" ||
          data.id !== id
        ) {
          return;
        }
        window.removeEventListener("message", onMessage);
        if (data.error) {
          reject(new Error(data.error));
        } else {
          resolve(data.file);
        }
      };
      window.addEventListener("message", onMessage);
      window.postMessage(
        { type: "ig-stories:pick-google-photo", id },
        location.origin,
      );
    });
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
    const fileInput = element("input", {
      type: "file",
      accept: "image/*,video/*",
      hidden: true,
    });

    const swatches = element("div", { className: "swatches", hidden: true });
    const swatchButtons = BACKGROUNDS.map((background) => {
      const swatch = element("button", { className: "swatch" });
      swatch.style.background = cssBackground(background);
      swatch.onclick = () => pickBackground(swatch, background);
      return swatch;
    });
    swatches.append(...swatchButtons);

    const zoomInput = element("input", {
      type: "range",
      min: 0.5,
      max: 5,
      step: 0.01,
      value: 1,
    });
    const moveButton = element("button");
    const photoRow = element("div", { className: "row", hidden: true });
    photoRow.append(
      element("span", { textContent: "Zoom" }),
      zoomInput,
      moveButton,
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
    controls.append(photoRow, textInput, sizeRow);

    const cancel = element("button", { textContent: "Cancel" });
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
    const reviewBar = element("div", { className: "bar", hidden: true });
    reviewBar.append(back, done);

    const overlay = element("div", { className: "overlay" });
    overlay.append(stage, message, swatches, controls, cameraBar, reviewBar);
    root.append(overlay, fileInput);
    document.documentElement.append(host);

    let stream;
    // Either { colors } or { image, zoom, x, y }.
    let base;
    let dragTarget = "text";
    let lastPoint;
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
      photoRow.hidden = mode !== "photo";
      back.textContent = backLabel;
    };
    const setDragTarget = (target) => {
      dragTarget = target;
      moveButton.textContent =
        target === "photo" ? "Moving photo" : "Moving text";
    };
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
      setZoom(fill ? fillZoom : 1);
      setDragTarget("photo");
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
      showDiscard();
    };

    const openFile = async (file) => {
      if (!file.type.startsWith("image/")) {
        handOff(file);
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
        const file = await pickGooglePhoto();
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
      pickBackground(selected, BACKGROUNDS[swatchButtons.indexOf(selected)]);
      setDragTarget("text");
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

    zoomInput.oninput = () => setZoom(Number(zoomInput.value));
    moveButton.onclick = () =>
      setDragTarget(dragTarget === "photo" ? "text" : "photo");

    // Keep Instagram's keyboard shortcuts from reacting to typing.
    textInput.addEventListener("keydown", (event) => event.stopPropagation());
    textInput.oninput = () => {
      text.value = textInput.value;
      setDragTarget("text");
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
      if (dragTarget === "photo" && base.image) {
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
