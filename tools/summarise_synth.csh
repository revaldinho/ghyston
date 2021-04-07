#!/bin/tcsh -f

if ( -e synth.csv) rm -f synth.csv
set header = ""
foreach dir ( `ls -1 | grep pipe`)

    # Find the absolute best performing TWR file
    pushd $dir
    rm -rf best_system.*
    
    set best_twr = `find . -name '*twr' -exec grep -H 'frequency' {} \; | sort -k 4 -n | head -1 | sed 's/://g' | awk '{print $1}'`
    set best_par = `find . -name '*twr' -exec grep -H 'frequency' {} \; | sort -k 4 -n | head -1 | sed 's/://g' | sed 's/twr/par/g' | awk '{print $1}'`

    cp $best_twr best_system.twr
    cp $best_par best_system.par
    popd

    python3 ../tools/synth_stats.py $dir $header >> synth.csv
    set header = "no_header"
end
