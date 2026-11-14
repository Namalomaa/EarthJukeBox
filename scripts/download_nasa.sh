#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (nameeraaa): " username
    username=${username:-nameeraaa}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_233655_FIN.nc"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_233655_FIN.nc -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_233655_FIN.nc | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_233655_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_220419_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_203144_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_185908_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_172633_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_155357_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_142122_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_124846_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_111611_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_094335_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_081100_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_063824_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_050549_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_033313_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_020037_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170311_002802_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_225527_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_212251_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_195016_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_181740_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_164505_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_151229_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_133953_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_120718_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_103442_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_090207_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_072931_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_055656_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_042420_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_025144_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170310_011909_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_234634_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_221358_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_204123_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_190847_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_173612_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_160336_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_143100_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_125825_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_112549_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_095314_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_082038_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_064803_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_051527_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_034251_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_021016_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170309_003740_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_230505_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_213229_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_195953_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_182718_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_165442_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_152207_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_134931_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_121656_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_104420_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_091144_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_073909_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_060633_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_043358_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_030122_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170308_012847_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_235938_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_222335_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_205059_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_191824_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_174548_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_161313_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_144037_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_130801_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_113526_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_100250_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_083015_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_065739_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_052503_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_035228_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_021952_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170307_004716_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_231441_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_214205_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_200929_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_183654_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_170418_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_153142_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_135907_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_122631_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_105355_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_092120_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_074844_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_061609_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_044333_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_031057_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_013822_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170306_000546_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_223310_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_210034_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_175523_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_162248_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_145012_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_131736_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_114500_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_101224_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_083949_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_070713_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_053438_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_040202_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_022926_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170305_005651_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_232415_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_215139_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_201903_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_184628_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_171352_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_154116_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_032031_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_014755_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170304_001519_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_224243_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_211008_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_193732_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_180456_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_163221_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_145945_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_132709_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_115433_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_102157_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_084922_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_071646_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_054410_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_041134_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_023859_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170303_010623_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_233347_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_220111_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_202835_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_185600_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_172324_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_155048_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_141812_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_124537_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_111301_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_094025_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_080749_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_063514_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_050238_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_033002_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_015727_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170302_002453_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_225219_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_211944_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_194710_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_181435_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_164201_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_150926_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_133652_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_120418_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_103143_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_085909_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_072634_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_055400_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_042125_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_024851_FIN.nc
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/isslis_v3_fin__3/ISS_LIS_SC_V3.0_20170301_011617_FIN.nc
EDSCEOF