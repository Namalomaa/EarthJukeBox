// Temporary ASTRO GEEKS bridge: NASA JSON -> Rawaa's functions -> Saba's audio events.
// No audio playback here. This is intentionally a prototype mapping.
import { normalize, mapToPitch, mapToRhythm } from './sonification.js';

const SCALE_HZ = [220, 261.63, 293.66, 329.63, 392];
const SEGMENT_SECONDS = 2; // each NASA 10-minute window is compressed to 2 s of music
const MAX_NOTES_PER_WINDOW = 12;
const NOTE_DURATION_SECONDS = 0.12;

export function createEvents(data) {
  if (!data || !Array.isArray(data.flashes) || !Array.isArray(data.windows)) {
    throw new Error('Expected lightning.json to contain flashes[] and windows[]');
  }
  const flashes = data.flashes.filter(f =>
    typeof f.time === 'string' && Number.isFinite(Date.parse(f.time)) &&
    Number.isFinite(f.latitude) && Number.isFinite(f.longitude) &&
    Number.isFinite(f.radiance)
  ).sort((a, b) => Date.parse(a.time) - Date.parse(b.time));
  const radiances = flashes.map(f => f.radiance);
  const minRadiance = radiances.length ? Math.min(...radiances) : 0;
  const maxRadiance = radiances.length ? Math.max(...radiances) : 1;
  const windows = [...data.windows].sort((a, b) => Date.parse(a.start) - Date.parse(b.start));
  const events = [];

  windows.forEach((window, windowIndex) => {
    const startMs = Date.parse(window.start);
    const endMs = Date.parse(window.end);
    if (!(endMs > startMs)) throw new Error(`Invalid window: ${window.start}`);
    const windowFlashes = flashes.filter(f => {
      const t = Date.parse(f.time);
      return t >= startMs && t < endMs;
    });
    const noteCount = Math.min(windowFlashes.length, MAX_NOTES_PER_WINDOW);
    if (!noteCount) return;
    const rhythm = mapToRhythm(noteCount); // Rawaa's timeWindow=2000ms = AUDIO segment time
    for (let i = 0; i < noteCount; i++) {
      // Deterministically sample evenly across the detected flashes.
      const flash = windowFlashes[Math.floor(i * windowFlashes.length / noteCount)];
      const pitchHz = mapToPitch(normalize(flash.latitude, -90, 90), SCALE_HZ);
      const pan = normalize(flash.longitude, -180, 180) * 2 - 1;
      // For this demo only: relative optical radiance -> note velocity, not lightning energy.
      const intensity = maxRadiance > minRadiance
        ? normalize(flash.radiance, minRadiance, maxRadiance) : 0.5;
      events.push({
        startTime: windowIndex * SEGMENT_SECONDS + i * rhythm.interval / 1000,
        pitchHz,
        duration: NOTE_DURATION_SECONDS,
        velocity: 0.25 + 0.45 * intensity,
        pan,
        instrument: 'synth',
        sourceTime: flash.time,
        sourceLatitude: flash.latitude,
        sourceLongitude: flash.longitude
      });
    }
  });
  return {
    events,
    totalDuration: windows.length * SEGMENT_SECONDS,
    windowCount: windows.length,
    flashCount: flashes.length,
    maxNotesPerWindow: MAX_NOTES_PER_WINDOW,
    noteFormat: 'pitchHz (frequency in Hz)',
    noteTiming: '2 audio seconds per 10-minute NASA window',
  };
}
