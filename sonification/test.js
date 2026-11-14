
import fs from "node:fs";

import {
  normalize,
  mapToPitch,
  mapToRhythm
} from "./sonification.js";

// Read real NASA data
const raw = fs.readFileSync(
  new URL("../data/processed/lightning.json", import.meta.url),
  "utf8"
);

const data = JSON.parse(raw);

// Rawaa's temporary scale uses frequencies in Hz
const scale = [220, 261.63, 293.66, 329.63, 392];

console.log("NASA flashes:", data.flashes.length);
console.log("NASA windows:", data.windows.length);

// Test individual lightning flashes
console.log("\n--- PITCH TEST ---");

for (const flash of data.flashes.slice(0, 5)) {
  const normalized = normalize(
    flash.latitude,
    -90,
    90
  );

  const pitch = mapToPitch(normalized, scale);

  console.log({
    time: flash.time,
    latitude: flash.latitude,
    pitchHz: pitch
  });
}

// Test flash counts from 10-minute windows
console.log("\n--- RHYTHM TEST ---");

for (const window of data.windows.slice(0, 5)) {
  const rhythm = mapToRhythm(window.flash_count);

  console.log({
    start: window.start,
    flashCount: window.flash_count,
    intervalMs: rhythm.interval,
    density: rhythm.density
  });
}

