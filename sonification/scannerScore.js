
// ISS LIS V3 spatial scanner score.
// Scanner order is longitude (west -> east),
// not chronological flash time.

import {
  mapToPitchWithDensity,
  mapToIntensity
} from './sonification.js';

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

const scale = [
  48, 50, 52, 55, 57,
  60, 62, 64, 67, 69,
  72, 74, 76, 79, 81
];

// Convert MIDI note to frequency (Hz)
export const noteHz = n => 440 * 2 ** ((n - 69) / 12);

// Group NASA lightning flashes by UTC date
export function buildDayIndex(input) {
  const source = Array.isArray(input) ? input : input.flashes;

  if (!Array.isArray(source)) {
    throw Error('Missing flashes array');
  }

  const grouped = new Map();

  for (const f of source) {
    if (
      typeof f.time !== 'string' ||
      !Number.isFinite(Date.parse(f.time)) ||
      ![f.latitude, f.longitude, f.radiance].every(
        v => Number.isFinite(Number(v))
      )
    ) {
      continue;
    }

    const key = f.time.slice(0, 10);

    if (!grouped.has(key)) {
      grouped.set(key, []);
    }

    grouped.get(key).push({
      time: f.time,
      latitude: +f.latitude,
      longitude: +f.longitude,
      radiance: +f.radiance
    });
  }

  for (const group of grouped.values()) {
    group.sort(
      (a, b) =>
        a.longitude - b.longitude ||
        a.time.localeCompare(b.time)
    );
  }

  const dates = [...grouped.keys()].sort();

  if (!dates.length) {
    return [];
  }

  const first = dates[0];
  const last = dates[dates.length - 1];

  const days = [];

  for (
    let d = new Date(first + 'T00:00:00Z'),
      end = new Date(last + 'T00:00:00Z');
    d <= end;
    d.setUTCDate(d.getUTCDate() + 1)
  ) {
    const day = d.toISOString().slice(0, 10);

    days.push({
      day,
      flashes: grouped.get(day) || []
    });
  }

  return days;
}

// Build the sound events for one selected day
export function buildScannerScore(day, seconds = 24, columns = 48) {
  const flashes = day.flashes;

  if (!Array.isArray(flashes)) {
    throw Error('Missing day flashes');
  }

  if (columns <= 0 || !Number.isInteger(columns) || seconds <= 0) {
    throw Error('Invalid scanner dimensions');
  }

  // Maximum radiance for normalizing sound intensity
  const maxRadiance = Math.max(
    1,
    flashes.reduce(
      (max, f) => Math.max(max, Number(f.radiance) || 0),
      0
    )
  );

  // Rawaa's pitch function expects frequencies, not MIDI values
  const scaleHz = scale.map(noteHz);

  // Divide Earth into longitude bands
  const byColumn = Array.from(
    { length: columns },
    () => []
  );

  for (const f of flashes) {
    const column = clamp(
      Math.floor((f.longitude + 180) / 360 * columns),
      0,
      columns - 1
    );

    byColumn[column].push(f);
  }

  // Largest detection count among longitude bands
  const maxCount = Math.max(
    1,
    ...byColumn.map(group => group.length)
  );

  const events = [];

  // Scan Earth west to east
  byColumn.forEach((group, i) => {
    if (!group.length) return;

    const density = group.length / maxCount;

    // Higher density can generate more musical voices
    const voices = Math.min(
      5,
      1 + Math.floor(Math.log2(group.length + 1))
    );

    // Select actual NASA detections
    const sorted = [...group].sort(
      (a, b) => b.radiance - a.radiance
    );

    for (let j = 0; j < voices; j++) {
      const index = Math.min(
        sorted.length - 1,
        Math.floor((j + 0.5) * sorted.length / voices)
      );

      const f = sorted[index];

      // RAWAA: latitude determines base pitch.
      // Higher detection density raises its register.
      const frequencyHz = mapToPitchWithDensity(
        f.latitude,
        scaleHz,
        group.length,
        0,
        maxCount
      );

      // Convert frequency to MIDI for the existing audio engine
      const note = Math.round(
        69 + 12 * Math.log2(frequencyHz / 440)
      );

      // RAWAA: radiance + density determine intensity
      const velocity = mapToIntensity(
        Math.max(0, f.radiance),
        0,
        maxRadiance,
        group.length,
        0,
        maxCount
      );

      events.push({
        at: i * seconds / columns + j * 0.045,
        duration: 0.20 + 0.14 * density,
        note,
        velocity,
        flash: f,
        column: i,
        sectionCount: group.length
      });
    }
  });

  return {
    events,
    byColumn,
    seconds,
    columns,
    day: day.day,
    count: flashes.length
  };
}
