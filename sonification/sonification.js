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
// Maps latitude and flash count to pitch
export function mapToPitchWithDensity(
  latitude,
  scale,
  flashCount,
  minFlashCount,
  maxFlashCount,
  maxRegisterSteps = 12
) {
  if (!Array.isArray(scale) || scale.length === 0) {
    throw new Error('Scale must be a non-empty array');
  }

  if (flashCount < 0 || minFlashCount < 0 || maxFlashCount < minFlashCount) {
    throw new Error('Invalid flash count range');
  }

  // Latitude determines the base pitch
  const latitudeValue = normalize(latitude, -90, 90);
  const baseIndex = Math.round(latitudeValue * (scale.length - 1));
  const basePitch = scale[baseIndex];

  // Flash count raises the pitch
  const density = maxFlashCount === minFlashCount
    ? 0
    : normalize(flashCount, minFlashCount, maxFlashCount);

  const registerShift = density * maxRegisterSteps;

  return basePitch * Math.pow(2, registerShift / 12);
}
// Maps radiance and flash count to sound intensity
export function mapToIntensity(
  radiance,
  minRadiance,
  maxRadiance,
  flashCount,
  minFlashCount,
  maxFlashCount
) {
  if (radiance < 0) {
    throw new Error('Radiance cannot be negative');
  }

  if (flashCount < 0 || minFlashCount < 0 || maxFlashCount < minFlashCount) {
    throw new Error('Invalid flash count range');
  }

  // Radiance determines the base intensity
  const radianceValue = normalize(
    radiance,
    minRadiance,
    maxRadiance
  );

  // Flash count adds an intensity boost
  const density = maxFlashCount === minFlashCount
    ? 0
    : normalize(flashCount, minFlashCount, maxFlashCount);

  const intensity = 0.2 + (radianceValue * 0.6) + (density * 0.2);

  return Math.max(0, Math.min(1, intensity));
}

