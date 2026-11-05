// Copies extensions/ig-plus into target/ig-plus-chrome for the Chrome Web
// Store, which rejects a manifest key and assigns the item ID itself.
import { cp, readFile, rm, writeFile } from "node:fs/promises";

const source = new URL("../extensions/ig-plus/", import.meta.url);
const target = new URL("../target/ig-plus-chrome/", import.meta.url);

const manifest = JSON.parse(
  await readFile(new URL("manifest.json", source), "utf8"),
);
delete manifest.key;

await rm(target, { recursive: true, force: true });
await cp(source, target, { recursive: true });
await writeFile(
  new URL("manifest.json", target),
  `${JSON.stringify(manifest, null, 2)}\n`,
);
console.log(`Built ${target.pathname}`);
