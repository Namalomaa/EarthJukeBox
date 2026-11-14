
import json
from collections import Counter
from datetime import datetime, timedelta
from pathlib import Path

from netCDF4 import Dataset

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
OUTPUT = ROOT / "data" / "processed" / "lightning.json"

WINDOW_MINUTES = 10


def to_iso(dt):
    return dt.isoformat().replace("+00:00", "Z")


def create_windows(flashes):
    counts = Counter()

    for flash in flashes:
        dt = datetime.fromisoformat(
            flash["time"].replace("Z", "+00:00")
        )

        # Round down to the nearest 10-minute boundary
        window_start = dt.replace(
            minute=(dt.minute // WINDOW_MINUTES)
            * WINDOW_MINUTES,
            second=0,
            microsecond=0,
        )

        counts[window_start] += 1

    windows = []

    for start, count in sorted(counts.items()):
        end = start + timedelta(minutes=WINDOW_MINUTES)

        windows.append({
            "start": to_iso(start),
            "end": to_iso(end),
            "flash_count": count,
        })

    return windows


def main():
    files = sorted(RAW_DIR.glob("*.nc"))

    if not files:
        raise FileNotFoundError("No .nc files found")

    flashes = []

    for file_path in files:
        print(f"Processing: {file_path.name}")

        with Dataset(file_path, "r") as ds:
            utc_start = datetime.fromisoformat(
                str(ds.variables["orbit_summary_UTC_start"][...])
                .replace("Z", "+00:00")
            )

            tai_start = float(
                ds.variables["orbit_summary_TAI93_start"][...]
            )
            if "lightning_flash_TAI93_time" not in ds.variables:
                print(f"No flash data in {file_path.name}, skipping flashes.")
                continue
            times = ds.variables["lightning_flash_TAI93_time"][:]
            lats = ds.variables["lightning_flash_lat"][:]
            lons = ds.variables["lightning_flash_lon"][:]
            radiances = ds.variables["lightning_flash_radiance"][:]

            for tai, lat, lon, radiance in zip(
                times, lats, lons, radiances
            ):
                offset = float(tai) - tai_start
                utc_time = utc_start + timedelta(seconds=offset)

                flashes.append({
                    "time": to_iso(utc_time),
                    "latitude": float(lat),
                    "longitude": float(lon),
                    "radiance": float(radiance),
                })

    flashes.sort(key=lambda flash: flash["time"])

    windows = create_windows(flashes)

    result = {
        "source": "NASA ISS LIS Science Data V3",
        "window_minutes": WINDOW_MINUTES,
        "flash_count": len(flashes),
        "radiance_unit": "uJ/sr/m2/um",
        "observation_coverage": "not_evaluated",
        "flashes": flashes,
        "windows": windows,
    }

    # Verify that every extracted flash was counted
    assert sum(w["flash_count"] for w in windows) == len(flashes)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with OUTPUT.open("w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, allow_nan=False)

    print(f"\nProcessed {len(files)} NetCDF file(s)")
    print(f"Extracted {len(flashes)} flashes")
    print(f"Created {len(windows)} time windows")
    print(f"Saved to: {OUTPUT}")

    print("\nFirst 5 windows:")
    for window in windows[:5]:
        print(window)


if __name__ == "__main__":
    main()

