#!/usr/bin/env bash

# Bash script to retrieve NHC-related information.
# Author: Brandon Molyneaux
# Date: Sunday, Aug 29 2021
# Usage
#   ./nhc.sh [flags]
# where:
#   date is in YYYYMMDD format
#   outlook is in zulu (1200 is 12z, etc)
# Note: This assumes day 1. This will not assume any other days currently.
# Note: The KML file format changed slightly. Does not work pre-2017.

self=$0

help_menu()
{
  cat <<END_HELP
Bash script to get various GIS files from the National Hurricane Center.

   Usage: $self -[c|w|t] year name advisory_number

Options:

    c             Adds cone of uncertainty for specified TC.
    w             Adds watches and warnings for specified TC.
    t             Adds track for the specified TC.
    -h | --help   Prints this menu.

END_HELP
}

# Check user input to ensure it's correct: number of arguments
if [[ $# -ne 4 ]]; then
  echo "Wrong number of arguments. Use $self -h to see usage."
  exit
fi

# empty is don't donwload. otherwise, download.
c_flag=
w_flag=
t_flag=

# Handle arguments
POSITIONAL=() # store positional arguments.
while (( $# )); do
  case $1 in

    -h|--help)  help_menu exit 1;;
    -c) c_flag=0;;
    -w) w_flag=0;;
    -t) t_flag=0;;
    -cw|-wc)
      c_flag=0 w_flag=0;;
    -ct|-tc)
      c_flag=0 t_flag=0;;
    -wt|-tw) # only watches and
      w_flag=0 t_flag=0;;
    -cwt|-ctw|-tcw|-twc|-wtc|-wct) # all options selected
      c_flag=0 w_flag=0 t_flag=0;;
    -*) # has a flag, but unknown flag.
      printf 'Unknown option: %q\n\n' "$1" exit 1;;
    *)
      POSITIONAL+=("$1");;
  esac
  shift
done

# == Year ==
YEAR="${POSITIONAL[0]}"

year_re='^[0-9]+$'
if ! [[ $YEAR =~ $year_re ]] ; then
   printf "Year is not a number. Found: %s\n" "$YEAR"
   exit 1;
fi

# Validate year input.
if [[ ${#YEAR} -ne 4 ]]; then
  LEN=${#YEAR}
  printf "Year is not 4 characters. Length of year: %s\n" "$LEN"
  exit 1;
fi

# == Identifier ==
IDENTIFIER="${POSITIONAL[1]}"

# Validate identifier input.
if [[ ${#IDENTIFIER} -ne 4 ]]; then
  LEN=${#IDENTIFIER}
  printf "Identifier is not 4 characters. Length of identifier: %s\n" "$LEN"
  exit 1;
fi

iden_re='[aAeE][lLpP][0-9][0-9]'
if ! [[ $IDENTIFIER =~ $iden_re ]]; then
  printf "Identifier is not proper format. Expected: al/ep##. Found: %s\n" "$IDENTIFIER"
  exit 1;
fi

# make sure identifier is capitalized.
IDENTIFIER_UPPER=$(tr '[a-z]' '[A-Z]' <<< ${IDENTIFIER:0:2})
IDENTIFIER="${IDENTIFIER_UPPER}${IDENTIFIER:2:2}"

# == Advisory Number ==
ADV_N="${POSITIONAL[2]}"
if ! [[ $YEAR =~ $year_re ]] ; then
   printf "Advisory number is not a number. Found: %s\n" "$YEAR"
   exit 1;
fi

if [[ ${#YEAR} -gt 4 ]]; then
  LEN=${#YEAR}
  printf "Advisory number can't exceed 3 digits. Found: %s\n" "$LEN"
  exit 1;
fi

# Pad the advisory Number
while [ ${#ADV_N} -ne 3 ]; do
  ADV_N="0"$ADV_N
done

printf "year: %s\n" "$YEAR"
printf "identifier %s\n" "${IDENTIFIER:0:2}${IDENTIFIER:2:2}"
printf "advisory number: %s\n" "$ADV_N"

# Create the base URL
# https://www.nhc.noaa.gov/gis/archive/2012/EP172012_015adv_CONE.kmz
BASE_URL="https://www.nhc.noaa.gov/gis/archive/${YEAR}/${IDENTIFIER}${YEAR}_${ADV_N}adv_"
BASE_FNAME="${IDENTIFIER}${YEAR}_${ADV_N}adv_"

# Use flags to determine what files to download.

download_unzip() {
  # check to see if save directory is there. If not, create it.
  save_dir="temp"
  if [[ ! -e  $save_dir ]]; then
    mkdir $save_dir # if it doesn't create it.
  fi

  wget -P $save_dir $URL

  temp_zip="temp.zip"
  cp $save_dir/$FNAME $save_dir/$temp_zip
  unzip $save_dir/$temp_zip -d $save_dir

  find . -type f ! -name 'temp/*.kml' -delete
}


if [[ $c_flag ]]; then
  URL="${BASE_URL}CONE.kmz"
  FNAME="${BASE_FNAME}CONE.kmz"
  download_unzip # call function
fi
