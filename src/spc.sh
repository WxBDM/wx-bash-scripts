#!/usr/bin/env bash

# Bash script to retrieve and display the highest categorial risk for the day.
# Author: Brandon Molyneaux
# Date: Monday, Aug 23 2021
# Usage
#   ./spc.sh date outlook
# where:
#   date is in YYYYMMDD format
#   outlook is in zulu (1200 is 12z, etc)
# Note: This assumes day 1. This will not assume any other days currently.
# Note: The KML file format changed slightly. Does not work pre-2017.

# Dev note: Unknown on when the file format changed, but testing on a dataset from
# May 24, 2016: <SimpleData name="Name">Enhanced Risk</SimpleData>

# Validate user input for outlook.
if [[ ! $1 ]]; then # check to ensure that the date is inputted.
  printf "Date parameter is not entered.\n"
  exit 1
fi
if [[ ! $2 ]]; then # check to make sure issuance time is inputted.
  printf "Issuance time parameter is not entered.\nOptions: 0600, 1300, 1630, 2000, or 0100\n"
  exit 1
fi
if [[ $2 != "0600" ]] && [[ $2 != "1300" ]] && [[ $2 != "1630" ]] && [[ $2 != "2000" ]] && [[ $2 != "0100" ]]; then
  printf "%s is not a valid input for outlook time. Choose 0600, 1300, 1630, 2000, or 0100\n" "$2"
  exit 1
fi

# some variables
save_dir="temp" # a temporary folder to save stuff in.
d1_otlk_link="https://www.spc.noaa.gov/products/outlook/archive/${1:0:4}/day1otlk_${1}_${2}.kmz"
fname="day1otlk_${1}_${2}" # name of the file, used below.
kmz_file="$save_dir/${fname}.kmz" # the name of the kmz file
kml_file="$save_dir/${fname}.kml" # the name of the kml file

# check to see if directory exists
if [[ ! -e $save_dir ]]; then
  mkdir $save_dir # if it doesn't create it.
else
  printf "%s is already created. Halting script execution.\n" "$save_dir"
  exit 1
fi

# check to see if the file already exists.
# NOTE: the URL will be dynamic at a later point. This check will change.
if [[ -f $kmz_file ]]; then
  printf "%s exists already. Exiting." "$kmz_file"
  exit 1
fi

# check to see if the associated kml file exists. If so, delete.
if [[ -f $kml_file ]]; then
  rm $kml_file
fi

# get the file from the server
wget -P $save_dir $d1_otlk_link

# Zip the file, then unzip. This gets KML version.
temp_zip="temp.zip"
cp $save_dir/"${fname}.kmz" $save_dir/$temp_zip
unzip $save_dir/$temp_zip -d $save_dir

# Delete the zip file, it's not needed.
rm $save_dir/$temp_zip
rm $save_dir/${fname}.kmz

# Get all SimpleData with risk, this will allow us to get the highest risk for the day.
# Iteratation through high, moderate, etc was the easiest solution.
# note that slight and up may not be correct, needs to be fixed.
# See dev note at top of script.
for variable in "HIGH" "MDT" "ENH" "SLGT" "MRGL" "TSTM"; do
  data="<SimpleData name=\"LABEL\">$variable"
  out=$(grep "$data" $save_dir/${fname}.kml) # save grep output in a variable
  if [[ ! $out ]]; then # if there isn't a risk of that category, go to the next.
    continue
  else # otherwise, print out the highest risk and stop the loop.
    printf "\nHighest risk for the day: %s\n" "$variable"
    break
  fi
done

# remove the save directory too to keep the repo clean.
if [[ -e $save_dir ]]; then
  # Remove .DS_Store on macs.
  if [[ -e $save_dir/.DS_Store ]]; then
    rm $save_dir/.DS_Store
  fi
  if [[ -e $kml_file ]]; then
    rm $kml_file
  fi
  rmdir $save_dir
fi
