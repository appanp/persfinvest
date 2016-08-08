#!/bin/bash
#
# Script to convert data in multiple AxisDirect trade contract into one CSV file.
# 
files=$(ls $1/*.pdf)
for f in $files
do
	txt_file="./temp/"$(basename -s .pdf $f)".txt"
  pdftotext -nopgbrk -layout -upw AMAPP7314E $f $txt_file
	sed -n '/NSE-Cash/,/BSE EQUITY/p' $txt_file |sed -E -e '/^\s*$|Sub Total|Page\s+[0-9]+\s*of|NSE-Cash|BSE EQUITY/d' -e 's/^\s+//' -e 's/\s\s+/,/g' -e 's/^(\w+)$/,,,,\1/' >> stocks_data.csv
done