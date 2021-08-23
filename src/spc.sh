#!/usr/bin/env bash

# Bash script to retrieve and display information about SPC outlooks.
# Author: Brandon Molyneaux
# Date: Monday, Aug 23 2021

# Get day 1 outlook from server (using KML, easier to parse)
save_dir="outlooks"
d1_otlk_link="https://www.spc.noaa.gov/products/outlook/archive/2021/day1otlk_20210823_1300.kmz"

# check to see if directory exists
if [[ ! -e $save_dir ]]; then
  mkdir $save_dir # if it doesn't create it.
fi

# check to see if the file already exists.
# NOTE: the URL will be dynamic at a later point. This check will change.
fname="day1otlk_20210823_1300"
if [[ -f "$fname" ]]; then
  echo "day1otlk_20210823_1300.kmz exists already. Exiting."
  exit 1
fi

# get the file from the server
wget -P $save_dir $d1_otlk_link

# Zip the file, then unzip. This gets KML version.
temp_zip="temp.zip"
cp $save_dir/"${fname}.kmz" $save_dir/$temp_zip
unzip $save_dir/$temp_zip -d $save_dir

# Delete the zip file, it's not needed.
rm $save_dir/$temp_zip
rm $save_dir/${fname}.kml
