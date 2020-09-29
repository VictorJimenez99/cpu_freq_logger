#!/bin/bash

echo "Gathering data..."
date > log.txt
./freq_logger >> log.txt

echo "Generating Reports..."
Rscript script.R >> log.txt


