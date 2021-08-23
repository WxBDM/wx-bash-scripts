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

# get the file from the server
wget -P $save_dir $d1_otlk_link
