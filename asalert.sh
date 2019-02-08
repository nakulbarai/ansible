#!/bin/bash

###########################################################
# US Production Release Map health check
# Prog writes to log which is ingested into Splunk
# 2018-Nov
# dennis.rojas@tivo.com, jayesh.thomas@tivo.com
# dependencies: asalert.sh, asalert-wrapper.sh
###########################################################

myMSO=$1
myMapType=$2
progDir=/TivoData/relmap
myTime=`date --utc +%Y%m%d`
#rotateDate=`date --date="-1 day" --utc +%Y%m%d`
outputLog="${progDir}/log/asalertstatus.log"
rotatedLog="${progDir}/log/asalertstatus-${myTime}-$$.log"
targetHosts="${progDir}/hostnames.list"
mapInput="${progDir}/map/currentmap-${myMSO}_${myMapType}.txt"
mypidfile="${progDir}/run/asalert.pid"


# check if lock file exists
#if [ -e $mypidfile ]; then
  #echo "asalert.sh is already running"
  #exit 1
#else
# create a lock file
  #echo $$ > "$mypidfile"
#fi

function rotateLog {

if [ -e $outputLog ]; then
   echo "Output Log found, rotating existing log"
   mv $outputLog $rotatedLog
   gzip $rotatedLog
   touch $outputLog
else
   touch $outputLog
fi

} #end rotateLog func

function setValidMaps {
if [ $myMapType = "released" ]; then
   mapInput="${progDir}/map/currentmap-released_${myMSO}.txt"
fi

minSize=300
actualSize=$(wc -c <"$mapInput")
if [ $actualSize -ge "$minSize" ]; then
    echo "size is over $minSize bytes, proceeding with health check."
    testTargets
    echo "targets check completed for $mapInput"
    sleep 10
else
    echo "size is under $minSize bytes, not performing check."
fi
} #end setValidMaps func

function testTargets {
#declare -a bufferArr
#count=0

for url in `cat $mapInput  | awk -F"8080" {'print $2'}\;`
do
  for i in `cat $targetHosts`
  do
    currentTime=`date --utc +%Y%m%d_%H:%M:%S`
    curlResult=`curl -I -s http://$i:8080${url} | grep HTTP | awk {'print $2'}\;`
    echo "time=$currentTime|target-mso=$myMSO|target-host=$i|map-type=$mapInput|target-sw=$url|target-result=$curlResult" >> $outputLog 2>&1

    # Enable bufferred output
    #bufferArr+=("time=$currentTime|target-mso=$myMSO|target-host=$i|map-type=$mapInput|target-sw=$url|target-result=$curlResult")

    #count=$[$count +1]

    #if [ "$count" = 5 ]; then
      #for(( i=0; i<${#bufferArr[@]}; i++ )); do
        #echo ${bufferArr[$i]}
        #count=0
      #done
    #fi
    # Bufferred output END
  done
done
} #end testTargets func

#rotateLog
setValidMaps

# PID file is removed on program exit.
#trap "rm -f -- '$mypidfile'" EXIT
