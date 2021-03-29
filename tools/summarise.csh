#!/bin/tcsh -f

if ( -e heading.tmp ) rm heading.tmp
foreach f ( `ls -1 logs/*.csv` )
  cut -f 2 -d, $f > ${f}.data.tmp
end

set f = `ls -1 logs/*.csv | head -1`
cut -f 1 -d, $f > heading.tmp

paste -d, heading.tmp logs/*.data.tmp > summary.csv
rm -rf *.tmp logs/*tmp
