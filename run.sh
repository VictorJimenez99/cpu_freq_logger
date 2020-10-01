#!/bin/bash
DATE=$(date +\"%F_%H:%M:%S\")
DIR=$DATE
DIR="${DIR%\"}"
DIR="${DIR#\"}"

echo "Creating Output Directory..."
mkdir $DIR
echo "$DIR created..."

LOG="$DIR/log.txt"
echo $DATE > $LOG

echo "Gathering data..."
$(\time -o $LOG -a -f 'Total Time Gathering Data: %E\n' ./freq_logger $DIR >> $LOG)


echo "Generating Reports..."
Rscript script.R $DIR >> $LOG


echo "A Log File was created under the name: log.txt"


