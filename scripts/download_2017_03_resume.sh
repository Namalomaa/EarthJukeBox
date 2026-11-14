#!/usr/bin/env bash
# NASA Earthdata March 2017 resume script: downloads the remaining URL list.
# Run this inside ~/EarthJukeBox/data/raw with your activated Python venv.
set -u

cookiejar=$(mktemp)
netrc=$(mktemp)
chmod 600 "$cookiejar" "$netrc"
trap 'rm -f "$cookiejar" "$netrc"' EXIT

read -r -p "Earthdata username: " username
read -r -s -p "Earthdata password: " password
printf "\n"
printf 'machine urs.earthdata.nasa.gov login %s password %s\n' "$username" "$password" > "$netrc"
unset password

# Check existing files: don't skip an incomplete .nc from the interrupted run.
valid_nc() {
    python3 - "$1" <<'PYCHECK'
import sys
try:
    from netCDF4 import Dataset
    with Dataset(sys.argv[1], 'r') as ds:
        assert 'orbit_summary_TAI93_start' in ds.variables
except Exception:
    sys.exit(1)
PYCHECK
}

fetch_urls() {
    local url name tmp
    while IFS= read -r url; do
        [[ -n "$url" ]] || continue
        name="${url##*/}"
        name="${name%%\?*}"
        if [[ -f "$name" ]] && valid_nc "$name"; then
            printf 'SKIP (valid): %s\n' "$name"
            continue
        fi
        tmp="${name}.part"
        printf 'Downloading: %s\n' "$name"
        if curl --fail --location --retry 6 --retry-all-errors --retry-delay 5 \
            --connect-timeout 40 --netrc-file "$netrc" \
            --cookie "$cookiejar" --cookie-jar "$cookiejar" \
            --output "$tmp" -- "$url" && valid_nc "$tmp"; then
            mv -f -- "$tmp" "$name"
            printf 'OK: %s\n' "$name"
        else
            printf 'FAILED: %s. Re-run this script when your internet is stable.\n' "$name" >&2
            exit 1
        fi
    done
}

fetch_urls <<'EDSCEOF'
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_233154_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_215919_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_202644_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_185409_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_172134_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_154859_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_141624_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_124349_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_111113_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_093838_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_080603_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_063328_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_050053_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_032818_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_015543_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170331_002308_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170330_225033_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170330_211758_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170330_055207_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170330_041931_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170330_024656_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170330_011421_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_234146_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_220911_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_203636_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_190401_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_173126_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_155850_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_142615_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_125340_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_112105_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_094830_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_081555_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_064320_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_051044_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_033809_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_020534_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170329_003259_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_230024_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_212749_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_195514_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_182238_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_165003_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_151728_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_134453_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_121218_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_103942_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_090707_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_073432_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_060157_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_042922_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_025647_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170328_012411_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_235136_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_221901_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_204626_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_191351_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_174115_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_160840_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_143605_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_130330_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_113054_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_095819_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_082544_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_065309_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_052034_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_034758_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_021523_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170327_004248_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_231013_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_213738_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_200502_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_183227_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_165952_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_152717_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_135441_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_122206_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_104931_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_091656_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_074421_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_061145_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_043910_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_030635_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170326_013359_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_235939_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_222849_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_205614_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_192339_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_175103_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_161828_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_144553_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_131317_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_114042_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_100807_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_083532_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_070257_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_053021_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_035746_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_022511_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170325_005236_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_232000_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_214725_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_201450_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_184215_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_170939_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_153704_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_140429_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_123153_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_105918_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_092643_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_075408_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_062132_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_044857_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_031622_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_014347_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170324_001111_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_223836_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_210601_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_193325_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_180050_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_162815_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_145540_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_132304_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_115029_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_101754_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_084518_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_071243_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_054008_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_040733_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_023457_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170323_010222_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_232947_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_215711_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_202436_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_185201_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_171925_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_154650_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_141415_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_124139_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_110904_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_093629_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_080354_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_063118_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_045843_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_032608_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_015332_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170322_002057_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_224822_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_211546_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_194311_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_181036_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_163800_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_150525_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_133249_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_120014_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_102739_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_085503_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_072228_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_054953_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_041718_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_024442_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170321_011207_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_233931_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_220656_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_203421_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_190145_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_172910_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_155635_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_142359_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170320_003041_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170319_225806_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170319_212530_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170319_195255_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170319_182020_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170319_164744_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170319_151509_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_204405_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_191129_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_173854_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_160619_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_143343_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_130108_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_112832_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_095557_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_082322_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_065046_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_051811_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_034536_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_021300_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170318_004024_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_230749_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_213514_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_200238_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_183003_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_165728_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_152452_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_135217_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_121942_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_104706_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_091431_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_074155_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_060920_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_043645_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_030409_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170317_013134_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_235939_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_222623_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_205348_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_192112_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_174837_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_161601_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_144326_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_131051_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_113815_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_100540_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_083304_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_070029_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_052754_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_035518_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_022243_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170316_005008_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_231732_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_214457_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_201221_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_183946_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_170710_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_153435_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_140200_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_122924_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_105649_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_092413_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_075138_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_061902_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_044627_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_031352_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_014116_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170315_000841_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_223605_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_210330_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_145308_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_132033_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_114757_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_101522_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_084247_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_071011_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_053736_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_040500_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_023225_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170314_005949_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_232714_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_215439_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_202203_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_184928_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_171652_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_154417_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_141141_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_123906_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_110630_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_093355_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_080119_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_062844_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_045609_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_032333_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_015058_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170313_001822_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_224547_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_211311_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_194036_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_180800_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_163525_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_150249_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_133014_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_115738_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_102503_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_085228_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_071952_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_054716_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_041441_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_024206_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170312_010930_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_233655_FIN.nc
EDSCEOF