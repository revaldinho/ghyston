#!/bin/tcsh -f


set header = ""
foreach dir ( `ls -1 | grep pipe`)
        python3 ../tools/synth_stats.py $dir $header
        set header = "no_header"
end
