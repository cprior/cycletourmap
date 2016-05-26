#!/bin/bash
#/** 
#  * Download geodata files from various locations.
#  *
#  */

#ToDo: -f to skip asksure _FORCEDOWNLOAD=false
_CONFIGFILE="app/configuration/config.sh"
_VERBOSE=false
#_OSMDOWNLOADSGEOFABRIK="europe/germany/bremen-latest.osm.pbf" #Just some smallish file #ToDo remove
_NATURALEARTHDOWNLOAD="false"
_OSMDATADOWNLOAD="false"

while getopts ":hvc:" opt; do
  case $opt in
    h) echo "help!"
    ;;
    c) echo _CONFIGFILE=$OPTARG
    ;;
    v) _VERBOSE="true"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; echo -n "continuing "; sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo ".";
    ;;
  esac;
done

for d in 'app/bin' 'app/configuration' 'tec' 'data/incoming/osm' 'data/incoming/poly' 'data/incoming/gpx' 'data/incoming/naturalearth' 'data/incoming/openstreetmapdata' 'tmp' 'generated/Shapes' 'generated/osm' 'generated/Shapes/corridor'; do
  if [ ! -d $d ]; then mkdir -p $d; fi
done

gethelpers() {
  if [ ! -f 'app/bin/poly2osm.pl' ]; then wget -O 'app/bin/poly2osm.pl' http://svn.openstreetmap.org/applications/utils/osm-extract/polygons/poly2osm.pl; chmod +x 'app/bin/poly2osm.pl'; fi
  if [ ! -f 'app/bin/osm2poly.pl' ]; then wget -O 'app/bin/osm2poly.pl' http://svn.openstreetmap.org/applications/utils/osm-extract/polygons/osm2poly.pl; chmod +x 'app/bin/osm2poly.pl'; fi
  if [ ! -f 'app/bin/ogr2poly.py' ]; then wget -O 'app/bin/ogr2poly.py' http://svn.openstreetmap.org/applications/utils/osm-extract/polygons/ogr2poly.py; chmod +x 'app/bin/ogr2poly.py'; fi
} #end function gethelpers

checkrequirements() {
  i=0;
  #type foo >/dev/null 2>&1 || { echo >&2 "I require foo but it's not installed.  Aborting."; exit 1; }
  type wget >/dev/null 2>&1 || { echo >&2 "This script requires wget but it is not installed. ";  i=$((i + 1)); }
#  type osmosis >/dev/null 2>&1 || { echo >&2 "This script requires osmosis but it is not installed. "; i=$((i + 1)); }
  type unzip >/dev/null 2>&1 || { echo >&2 "This script requires unzip but it is not installed. ";  i=$((i + 1)); }
  type curl >/dev/null 2>&1 || { echo >&2 "This script requires curl but it is not installed. ";  i=$((i + 1)); }

  type app/bin/poly2osm.pl >/dev/null 2>&1 || { echo >&2 "This script requires app/bin/poly2osm.pl but it is not installed. ";  i=$((i + 1)); }
  type app/bin/osm2poly.pl >/dev/null 2>&1 || { echo >&2 "This script requires app/bin/osm2poly.pl but it is not installed. ";  i=$((i + 1)); }
  type app/bin/ogr2poly.py >/dev/null 2>&1 || { echo >&2 "This script requires app/bin/ogr2poly.py but it is not installed. ";  i=$((i + 1)); }

  if [[ $i > 0 ]]; then echo "Aborting."; echo "Please install the missing dependency."; exit 1; fi
} #end function checkrequirements

asksure() {
  if [ -z "$1" ]
    then echo -n "Please select [Y]es or [N]o: (Y/N)? "
  else
    echo "${1} (Y/N)"
  fi

  while read -r -n 1 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
echo
return $retval 
} #end function asksure




######################################################################
#/**
#  * Main part
#  *
#  */

gethelpers
checkrequirements
source $_CONFIGFILE;

#echo $_FORCEDOWNLOAD;
#echo $_CONFIGFILE;
#echo $_POLYDOWNLOADSGEOFABRIK

#/**
#  * Downloading poly file if specified in the configuration file
#  *
#  */
tmp=($_POLYDOWNLOADSGEOFABRIK)
if [ ${#tmp[@]} -gt 0 ]; then
  if [ "$_VERBOSE" = "true" ]; then _Q=" "; else _Q='-q'; echo -n "Testing for poly files"; fi;
  for f in ${_POLYDOWNLOADSGEOFABRIK}; do
    if [ ! -f ./data/incoming/poly/${f/\//-}.poly ]; then
      if [ "$_VERBOSE" != "true" ]; then echo -n "."; fi;
      #ToDo: May include the prefix in the config strings?
      wget "$_Q" http://download.geofabrik.de/${f}.poly -O ./data/incoming/poly/${f/\//-}.poly;
    else if [ "$_VERBOSE" = "true" ]; then echo "The poly file ${f} already existing in ./data/incoming/poly/"; fi;
    fi;
  done;
  echo -e "\nFinished providing poly files."
else
  echo "No poly files specified to download."
fi
unset tmp


#/**
#  * Downloading OSM files from geofabrik
#  *
#  * ToDo: Handle "latest" file different than checking for existence of "foo-latest.osm", probably wget -N will already do the trick?
#  */
tmp=($_OSMDOWNLOADSGEOFABRIK)
if [ ${#tmp[@]} -gt 0 ]; then
  if [ "$_VERBOSE" = "true" ]; then _Q=' '; else _Q='-q'; echo -n "Testing for OSM files"; fi;
  for f in ${_OSMDOWNLOADSGEOFABRIK}; do
    #//\//- means _all_ escaped \/ are replaced by - (more readable is //foo/bar, see also http://tldp.org/LDP/abs/html/string-manipulation.html )
    if [ ! -f ./data/incoming/osm/${f//\//-} ]; then
      #ToDO: -f option as force mit "asksure"
      if asksure "Downloading potentially large file ${f}?"; then
        #ToDo: Maybe download as .partial filename and move afterwards? Only then -c makes sense.
        #ToDo: May include the prefix in the config strings?
        wget "$_Q" --limit-rate=1000k http://download.geofabrik.de/${f} -c -O data/incoming/osm/${f//\//-};
      else
        echo -e "Maybe run later\nwget --limit-rate=1000k http://download.geofabrik.de/europe-140101.osm.pbf -c -O data/incoming/osm/${f//\//-}";
      fi
    else if [ "$_VERBOSE" = "true" ]; then echo "The OSM file ${f} already existing in ./data/incoming/osm/"; fi;
    fi;
  done;
  echo -e "\nFinished downloading OSM files."
else
  echo "No OSM files specified to download."
fi
unset tmp

#/**
#  * Downloading basic map shapes
#  *
#  */
if [ "$_NATURALEARTHDOWNLOAD" = "true" ]; then
  if [ "$_VERBOSE" = "true" ]; then _Q=' '; else _Q='-q'; echo "Testing for Natural_Earth_quick_start files"; fi;
  if [ ! -f data/incoming/naturalearth/Natural_Earth_quick_start.zip ]; then
     wget "$_Q" --limit-rate=1000k http://naciscdn.org/naturalearth/packages/Natural_Earth_quick_start.zip -c -O data/incoming/naturalearth/Natural_Earth_quick_start.zip.partial
     mv data/incoming/naturalearth/Natural_Earth_quick_start.zip.partial data/incoming/naturalearth/Natural_Earth_quick_start.zip
  fi
  if [ ! -f data/incoming/naturalearth/Natural_Earth_quick_start.zip ]; then
    echo "Unzipping"
    unzip "$_Q" -n data/incoming/naturalearth/Natural_Earth_quick_start.zip -d data/incoming/naturalearth/
  fi
  echo "Finished downloading and unpacking Natural_Earth_quick_start files."
fi

if [ "$_OSMDATADOWNLOAD" = "true" ]; then
  if [ "$_VERBOSE" = "true" ]; then _Q=' '; else _Q='-q'; echo "Testing for openstreetmapdata files"; fi;
  for f in coastlines-split-4326.zip water-polygons-split-4326.zip land-polygons-complete-4326.zip;
  do
    if [ ! -f "data/incoming/openstreetmapdata/${f}" ]; then
      wget "$_Q" --limit-rate=1000k http://data.openstreetmapdata.com/${f} -c -N -P data/incoming/openstreetmapdata/${f}
    fi
  done
  echo "Finished downloading openstreetmapdata files."
fi


