#!/bin/bash

###########################################################
# US Production Release Map health check
# Prog writes to log which is ingested into Splunk
# 2018-Nov
# dennis.rojas@tivo.com, jayesh.thomas@tivo.com
# dependencies: asalert.sh, asalert-wrapper.sh
###########################################################

TD=/TivoData
appDir=/TivoData/relmap
buildCMD=buildmap.sh
asalertCMD=$appDir/asalert.sh
MSO=(evo rcn cableco suddenlink comcast grande gci mediacom midco cableone abb buckeye blueridge cogeco wave astound armstrong entouch frontier wow nctc cableOnda sectv secv)
today=`date +%Y%d%m`

set -m # Enable Job Control

function activateVirtual_func {
cd $TD
source AutoStaging/bin/activate
cd $appDir
}

function alertCMD_func {

for i in ${MSO[@]}
do
  $asalertCMD $i rollout &
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done

for i in ${MSO[@]}
do
  $asalertCMD $i released &
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done

for i in ${MSO[@]}
do
  $asalertCMD $i encore &
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done

}

alertCMD_func
