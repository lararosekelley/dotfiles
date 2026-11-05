// Copies extensions/ig-plus into target/ig-plus-firefox with a manifest
// Firefox accepts: Firefox runs background scripts as an event page rather
// than a service worker, and has no use for Chrome's key, oauth2 client, or
// minimum version. Chrome rejects the developer key, so only Firefox gets it.
import { cp, readFile, rm, writeFile } from "node:fs/promises";

const source = new URL("../extensions/ig-plus/", import.meta.url);
const target = new URL("../target/ig-plus-firefox/", import.meta.url);

const manifest = JSON.parse(
  await readFile(new URL("manifest.json", source), "utf8"),
);
manifest.background = { scripts: [manifest.background.service_worker] };
delete manifest.key;
delete manifest.oauth2;
delete manifest.minimum_chrome_version;
manifest.developer = { name: "Lara Kelley", url: manifest.homepage_url };

await rm(target, { recursive: true, force: true });
await cp(source, target, { recursive: true });
await writeFile(
  new URL("manifest.json", target),
  `${JSON.stringify(manifest, null, 2)}\n`,
);
console.log(`Built ${target.pathname}`);
