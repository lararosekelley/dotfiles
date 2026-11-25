// Callie and Callie Light, from the palette in https://github.com/greylocklabs/themes
// (palettes/callie.toml). Headlamp runs this file as-is, with pluginLib in scope.

const font = ["Nunito", "system-ui", "sans-serif"];

pluginLib.registerAppTheme({
  name: "Callie",
  base: "dark",
  primary: "#f08fb8",
  secondary: "#33243a",
  secondaryContrastText: "#f6eef5",
  text: { primary: "#f6eef5" },
  link: { color: "#f08fb8" },
  background: { default: "#1c1220", surface: "#261a2a", muted: "#33243a" },
  sidebar: {
    background: "#140c17",
    color: "#c9b7c6",
    selectedBackground: "#f08fb8",
    selectedColor: "#2e0f20",
    actionBackground: "#33243a",
  },
  navbar: { background: "#1c1220", color: "#f6eef5" },
  terminal: {
    background: "#1c1220",
    foreground: "#e0d3df",
    cursor: "#f08fb8",
    ansi: {
      black: "#33243a",
      red: "#eaaba8",
      green: "#9dcca3",
      yellow: "#d6ba86",
      blue: "#a4beef",
      magenta: "#e5aac1",
      cyan: "#82cdcd",
      white: "#c9b7c6",
      brightBlack: "#9a8797",
      brightRed: "#fac5c2",
      brightGreen: "#bae0be",
      brightYellow: "#e8d1a8",
      brightBlue: "#bfd5fd",
      brightMagenta: "#f5c5d7",
      brightCyan: "#a6e1e1",
      brightWhite: "#f6eef5",
    },
  },
  radius: 11,
  buttonTextTransform: "none",
  fontFamily: font,
});

pluginLib.registerAppTheme({
  name: "Callie Light",
  base: "light",
  primary: "#c2407a",
  secondary: "#f3e7ee",
  secondaryContrastText: "#2b1a26",
  text: { primary: "#2b1a26" },
  link: { color: "#c2407a" },
  background: { default: "#fbf5f8", surface: "#fffafc", muted: "#f3e7ee" },
  sidebar: {
    background: "#fffafc",
    color: "#6b5562",
    selectedBackground: "#c2407a",
    selectedColor: "#fffafc",
    actionBackground: "#f3e7ee",
  },
  navbar: { background: "#fbf5f8", color: "#2b1a26" },
  terminal: {
    background: "#fffafc",
    foreground: "#2b1a26",
    cursor: "#c2407a",
  },
  radius: 11,
  buttonTextTransform: "none",
  fontFamily: font,
});
