#!/usr/bin/env bash

# Bash script to retrieve and display information about SPC outlooks.
# Author: Brandon Molyneaux
# Date: Monday, Aug 23 2021

# Get day 1 outlook from server (using KML, easier to parse)
save_dir="outlooks"
# At a future point, make this dynamic so it gets the most recent.
# For now, just use one.
d1_otlk_link="https://www.spc.noaa.gov/products/outlook/archive/2021/day1otlk_20210823_1300.kmz"
fname="day1otlk_20210823_1300"
kmz_file="$save_dir/${fname}.kmz" # the name of the kmz file
kml_file="$save_dir/${fname}.kml" # the name of the kml file

# check to see if directory exists
if [[ ! -e $save_dir ]]; then
  mkdir $save_dir # if it doesn't create it.
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
for variable in "HIGH" "MODR" "ENHA" "SLGT" "MRGL" "TSTM"; do
  data="<SimpleData name=\"LABEL\">$variable"
  out=$(grep "$data" $save_dir/${fname}.kml) # save grep output in a variable
  if [[ ! $out ]]; then # if there isn't a risk of that category, go to the next.
    continue
  else # otherwise, print out the highest risk and stop the loop.
    printf "\nHighest risk for the day: %s\n" "$variable"
    rm $kml_file # remove the kml file
    break
  fi
done

# remove the save directory too to keep the repo clean.
if [[ -e $save_dir ]]; then
  rm $save_dir/.DS_Store # only applicable on mac.
  rmdir $save_dir
fi
