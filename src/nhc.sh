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

   Usage: $self -[c|w|t] year storm_identifier advisory_number
   Usage: $self -[c|w|t] -i year storm_identifier advisory_number

   Examples:
   Hurricane Sandy, 15th Advisory, Cone Only
    $self -c 2012 al18 15
   Hurricane Eta, 9th Intermediate Advisory, Cone, Track, and Warnings
    $self -ctw 2020 al29 -i 9

Options:
    c             Includes KML of cone of uncertainty for specified TC.
    w             Includes KML of watches and warnings for specified TC.
    t             Includes KML of track for the specified TC.
    i             Specifies an intermediate advisory.
    -h | --help   Prints this menu.

END_HELP
}

# Download and unzip the KMZ file. Use in conjunction with delete_cone_and_track_info.
download_unzip() {
  # check to see if save directory is there. If not, create it.
  save_dir="downloads"
  if [[ ! -e  $save_dir ]]; then
    mkdir $save_dir # if it doesn't create it.
  fi

  # Save the error message into a variable.
  error_msg=$(cat <<END_ERROR
Download failed. Check parameters to ensure the year, advisory, and identifier are correct.

Attempted to download from: $URL
Year:             $YEAR
Advisory Number:  $ADV_N
Identifier:       $IDENTIFIER\n\n
END_ERROR)

  # Attempt to get the file from the URL. If not, display an error.
  wget -P $save_dir $URL || {
    printf "$error_msg"
    exit 1
  }

  # Zip then unzip.
  temp_zip="temp.zip"
  cp $save_dir/$FNAME $save_dir/$temp_zip
  unzip $save_dir/$temp_zip -d $save_dir
}

# Removes unecessary info, leave KML file. Manually put it in.
# Bad practice, but last time I deleted stuff recursively, the entire repo was
#   deleted. Oops.
delete_cone_and_track_info() {
  rm $save_dir/dPoint.png
  rm $save_dir/hPoint.png
  rm $save_dir/initalPoint.png # they misspelled it.
  rm $save_dir/initialPoint.png
  rm $save_dir/lPoint.png
  rm $save_dir/mPoint.png
  rm $save_dir/sPoint.png
  rm $save_dir/xdPoint.png
  rm $save_dir/xhPoint.png
  rm $save_dir/xmPoint.png
  rm $save_dir/xsPoint.png
  rm $save_dir/$FNAME
  rm $save_dir/temp.zip
}

delete_watches_warnings_unzip() {
  rm $save_dir/$FNAME
  rm $save_dir/temp.zip
}

success_message() {

  file_arr=()
  for entry in $save_dir/*
  do
    file_arr[${#file_arr[@]}]=$entry
  done

  cat <<END_SUCCESS

  Successfully downloaded the following files: ${file_arr[@]}

END_SUCCESS
}

# Check user input to ensure it's correct: number of arguments
if [[ $# -ne 4 ]] && [[ $# -ne 5 ]]; then
  echo "Wrong number of arguments. Use $self -h to see usage."
  exit
fi

# empty is don't donwload. otherwise, download.
c_flag= # cone flag
w_flag= # watches/warnings flag
t_flag= # track flag
intermediate_advisory_flag= # see name flag

# Handle arguments, read in flags. Positional args are dealt with later.
POSITIONAL=() # array to store positional arguments.
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
    -i)
      intermediate_advisory_flag=0;;
    -*) # has a flag, but unknown flag.
      printf 'Unknown option: %q\n\n' "$1" exit 1;;
    *)
      POSITIONAL+=("$1");;
  esac
  shift
done

# == Year ==
YEAR="${POSITIONAL[0]}"

# Validate year input: ensure it's numbers.
year_re='^[0-9]+$'
if ! [[ $YEAR =~ $year_re ]] ; then
   printf "Year is not a number. Found: %s\n" "$YEAR"
   exit 1;
fi

# Validate year input: ensure it's length of 4.
if [[ ${#YEAR} -ne 4 ]]; then
  LEN=${#YEAR}
  printf "Year is not 4 characters. Length of year: %s\n" "$LEN"
  exit 1;
fi

# == Identifier ==
IDENTIFIER="${POSITIONAL[1]}"

# Validate identifier input: length of 4.
if [[ ${#IDENTIFIER} -ne 4 ]]; then
  LEN=${#IDENTIFIER}
  printf "Identifier is not 4 characters. Length of identifier: %s\n" "$LEN"
  exit 1;
fi

# Validate identifier input: contains al/ep and a number (00-99)
iden_re='(([aA][lL])|([eE][pP]))[0-9]{2}'
if ! [[ $IDENTIFIER =~ $iden_re ]]; then
  printf "Identifier is not proper format. Expected: al/ep##. Found: %s\n" "$IDENTIFIER"
  exit 1;
fi

# make sure identifier is capitalized.
IDENTIFIER_UPPER=$(tr '[a-z]' '[A-Z]' <<< ${IDENTIFIER:0:2})
IDENTIFIER="${IDENTIFIER_UPPER}${IDENTIFIER:2:2}"

# == Advisory Number ==
ADV_N="${POSITIONAL[2]}"

# Validate advisory number: is a number.
# Note: reusing $YEAR variable and associated regex.
if ! [[ $YEAR =~ $year_re ]] ; then
   printf "Advisory number is not a number. Found: %s\n" "$YEAR"
   exit 1;
fi

# Validate advisory number: length. Must be less than 4 digits.
if [[ ${#YEAR} -gt 4 ]]; then
  LEN=${#YEAR}
  printf "Advisory number can't exceed 3 digits. Found: %s\n" "$LEN"
  exit 1;
fi

# Pad the advisory Number with 0's in front.
while [ ${#ADV_N} -ne 3 ]; do
  ADV_N="0"$ADV_N
done

# Create the base URL
#   https://www.nhc.noaa.gov/gis/archive/2012/EP172012_015adv_CONE.kmz
# 2005 - 2016 use the above. all else uses:
#   https://www.nhc.noaa.gov/storm_graphics/api/EP052018_005adv_CONE.kmz
if (( YEAR >= 2005 && YEAR <= 2016)); then
  GIS_URL="gis/archive/$YEAR"
else
  GIS_URL="storm_graphics/api"
fi

if [[ $intermediate_advisory_flag ]]; then # if it's an intermediate advisory
  BASE_URL="https://www.nhc.noaa.gov/$GIS_URL/${YEAR}/${IDENTIFIER}${YEAR}_${ADV_N}Aadv_"
  BASE_FNAME="${IDENTIFIER}${YEAR}_${ADV_N}Aadv_"
else # not an intermediate advisory.
  BASE_URL="https://www.nhc.noaa.gov/$GIS_URL/${IDENTIFIER}${YEAR}_${ADV_N}adv_"
  BASE_FNAME="${IDENTIFIER}${YEAR}_${ADV_N}adv_"
fi

# Based off of the flags given, download and save the files.
if [[ $c_flag ]]; then
  URL="${BASE_URL}CONE.kmz"
  FNAME="${BASE_FNAME}CONE.kmz"
  download_unzip # call function to download and unzip
  delete_cone_and_track_info # call function to delete cone-related information.
fi

if [[ $t_flag ]]; then
  URL="${BASE_URL}TRACK.kmz"
  FNAME="${BASE_FNAME}TRACK.kmz"
  download_unzip
  delete_cone_and_track_info
fi

if [[ $w_flag ]]; then
  URL="${BASE_URL}WW.kmz"
  FNAME="${BASE_FNAME}WW.kmz"
  download_unzip
  delete_watches_warnings_unzip
fi

success_message
