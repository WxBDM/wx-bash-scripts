# Bash Scripts: NWS Product Retrieval
This repository contains a few bash scripts to retrieve geographic information from the National Weather Service.

## Installation
To install, clone the repository and place it somewhere you can access it easily (i.e. Desktop). `cd` into this directory on terminal. You'll want to give yourself permissions to be able to run the script: `chmod u+x <file>` (i.e. `chmod u+x nhc.sh`).

## Usage
For each script, a small help menu has been included. Type `<filename> --help` or `<filename> -h` to display it.

### National Hurricane Center
The NHC provides geographic data of watches/warnings, track, and cone through KML files. These files can be easily used in conjunction with Google Earth. The NHC currently provides the files in a KMZ format. This script will download the associated KMZ and convert it into a KML file.

To use, `./nhc.sh [flags] [year] [ID] [Advisory Number]`. 
For example,
	`./nhc.sh -ctw 2020 al29 -i 9` will download the Cone (`-c`), Track (`-t`), and Watches/Warnings (`-w`) for Identifier AL29 from 2020 (Hurricane Zeta) for the intermediate advisory #9.
	`./nhc.sh -c 2012 al18 15` will download the Cone (`-c`) from identifier AL18 from 2012 (Hurricane Leslie) for the 15th advisory.

In the repository, you'll see a new folder: `downloads`. In this folder are the associated KML files that were requested.

### Storm Prediction Center
**Note:** This is currently a work in progress.
At this current time, SPC script downloads the Day 1 outlook KMZ and parses it to display the highest risk. However, this will change in a future update to be consistent with the goals of the NHC script.

