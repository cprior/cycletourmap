#!/bin/bash
#/** 
#  * Download geodata files from various locations.
#  *
#  */

shopt -s nullglob #to prevent errors with empty directory when read into array

for d in 'data/processing' './data/processing/poly2osm' './data/generated/poly' ; do
  if [ ! -d $d ]; then mkdir -p $d; fi
done

checkrequirements() {
  i=0;
  #type foo >/dev/null 2>&1 || { echo >&2 "I require foo but it's not installed.  Aborting."; exit 1; }
  type osmosis >/dev/null 2>&1 || { echo >&2 "This script requires osmosis but it is not installed. ";  i=$((i + 1)); }
  type osmosis-0.35 >/dev/null 2>&1 || { echo >&2 "This script requires osmosis-0.35 but it is not installed. ";  i=$((i + 1)); }

  if [[ $i > 0 ]]; then echo "Aborting."; echo "Please install the missing dependency."; exit 1; fi
} #end function checkrequirements



######################################################################
#/**
#  * Main part
#  *
#  */
checkrequirements

#todo use variables from config.sh
if [ ! -f './data/generated/asia-150101_europe-140101.merged.pbf' ]; then
  osmosis --read-pbf data/incoming/osm/asia-150101.osm.pbf --read-pbf ./data/incoming/osm/europe-140101.osm.pbf --merge --write-pbf ./data/generated/asia-150101_europe-140101.merged.pbf;
fi

for f in ./data/incoming/poly/*poly; do
  f2=$(basename $f)
  if [ ! -f "./data/processing/poly2osm/${f2}.v0.6_sorted.osm" ]; then
    echo "poly2osm $f"
    ./app/bin/poly2osm.pl $f > ./data/processing/poly2osm/${f2}.v0.5.osm
    osmosis-0.35 --read-xml-0.5 enableDateParsing=no file="./data/processing/poly2osm/${f2}.v0.5.osm" --migrate --write-xml file="./data/processing/poly2osm/${f2}.v0.6.osm"
    osmosis --read-xml ./data/processing/poly2osm/${f2}.v0.6.osm --sort --write-xml ./data/processing/poly2osm/${f2}.v0.6_sorted.osm
  else
    echo "./data/processing/poly2osm/${f2}.v0.6.osm existing"
  fi
done

if [ -f ./data/generated/poly/all.osm ]; then
  rm ./data/generated/poly/all.osm
fi

poly2osmfiles=(./data/processing/poly2osm/*.v0.6_sorted.osm)
if [ ${#poly2osmfiles[@]} -gt 0 ]; then
  string=""
  for f in ${poly2osmfiles[@]}; do
    string="$string --read-xml ${f}"  
  done
  i=1; while [ $i -lt ${#poly2osmfiles[@]} ]; do
    string="$string --merge"
    (( i++ ));
  done
fi

echo "merging into ./data/generated/poly/all.osm"
osmosis $string --write-xml ./data/generated/poly/all.osm
string=''

