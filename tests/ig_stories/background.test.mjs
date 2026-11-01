import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

const read = (name) =>
  readFile(
    new URL(`../../extensions/ig-stories/${name}`, import.meta.url),
    "utf8",
  );

// background.js only registers listeners at load, so every event is a no-op.
const events = new Proxy({}, { get: () => ({ addListener() {} }) });
const background = vm.createContext({
  chrome: { tabs: events, runtime: events },
});
vm.runInContext(await read("background.js"), background);

const mobileUserAgent = (source) => source.match(/MOBILE_UA =\s*"([^"]+)"/)[1];

test("rewrites the page request too, not just subresources", () => {
  const rule = background.mobileRule(7);
  // Copied out of the sandbox, whose arrays are from another realm.
  assert.deepEqual([...rule.condition.tabIds], [7]);
  assert.ok(rule.condition.resourceTypes.includes("main_frame"));
  const userAgent = rule.action.requestHeaders.find(
    ({ header }) => header === "user-agent",
  );
  assert.match(userAgent.value, /iPhone/);
});

test("drops every client hint header", () => {
  const removed = background
    .mobileRule(1)
    .action.requestHeaders.filter(({ operation }) => operation === "remove")
    .map(({ header }) => header);
  assert.ok(removed.includes("sec-ch-ua-mobile"));
  assert.ok(removed.includes("sec-ch-ua-platform"));
});

test("reads Google's durations", () => {
  assert.equal(background.milliseconds("5s", 0), 5000);
  assert.equal(background.milliseconds("3.5s", 0), 3500);
  assert.equal(background.milliseconds(undefined, 42), 42);
});

test("reports the same phone in headers and in the page", async () => {
  assert.equal(
    mobileUserAgent(await read("background.js")),
    mobileUserAgent(await read("mobile.js")),
  );
});
