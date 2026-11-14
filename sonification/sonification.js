/* Rawaa's original 3 functions (copied from the shared version; no logic changes). */
export function normalize(value, min, max) {
  if (max <= min) throw new Error('max must be greater than min');
  const normalized = (value - min) / (max - min);
  return Math.max(0, Math.min(1, normalized));
}
export function mapToPitch(value, scale) {
  if (!Array.isArray(scale) || scale.length === 0) throw new Error('Scale must be a non-empty array');
  if (value < 0 || value > 1) throw new Error('Value must be between 0 and 1');
  return scale[Math.round(value * (scale.length - 1))];
}
export function mapToRhythm(flashCount) {
  if (flashCount < 0) throw new Error('Flash count cannot be negative');
  const timeWindow = 2000;
  if (flashCount === 0) return { interval: null, density: 'none' };
  const interval = timeWindow / flashCount;
  const density = flashCount <= 2 ? 'low' : flashCount <= 5 ? 'medium' : 'high';
  return { interval, density };
}
