#
# Run this script from the sim/ area
#
import re
import sys
import os, os.path
import shutil

MAX_CPUS = 8
PI_ONLY = False

fixed_options = { "USE_STD_LIB":0 , "NOUNROLL_UDIV":1 }


options = [
    ("NEG_INSTR",[0,1]),
    ("MUL18X18",[0.1]),
    ("PRED_INSTR",[0,1]),
    ("ZLOOP_INSTR",[0,1]),
    ("DJNZ_INSTR",[0,1]),
    ("PIPE_STAGES",[2,3]),
    ("SHIFT_32",[0,1]),
]
if not os.path.exists("system_tb.v"):
    print ("ERROR - this script must be run from the sim/ directory")
    sys.exit(1)
for d in ( "logs", "options" ):
    if os.path.exists(d):
        shutil.rmtree(d)
    os.mkdir(d)
run_script = []
option_filename = ""
run_script.append ( "#!/bin/tcsh -f")
run_script.append ( "cp ../tests/options.h options/options.h_save")
run_script.append ( "if ( -e logs ) rm -rf logs/*stdout")
run = 0
for ineg in (options[0])[1]:
    for imul in (options[1])[1]:
        for ipred in (options[2])[1]:
            for izloop in options[3][1]:
                for idjnz in options[4][1]:
                    for ipipe in options[5][1]:
                        for ishift in options[6][1]:
                            iunroll = 0 if fixed_options["NOUNROLL_UDIV"] == 1 else fixed_options["NOUNROLL_UDIV"]
                            option_list = []
                            run_script.append("# ------------------------------------------------------------")
                            run_script.append("# Run number %s"% run)
                            run +=1
                            option_list.append("------------------------------------------------------------")
                            filebase = "mul%d_s32_%d_neg%d_zloop%d_djnz%d_pipe%d_urol%d_pred%d" %(imul,ishift,ineg,izloop,idjnz,ipipe,iunroll,ipred)
                            option_filename = ("options/%s.options.h" %(filebase))
                            option_list.append (";; %s" % option_filename)
                            option_list.append("------------------------------------------------------------")
                            for j in fixed_options:
                                option_list.append("%s#define %s %d" % (("" if fixed_options[j] else ";;"), j, fixed_options[j]))
                            option_list.append("%s#define %s %d" % (("" if ineg else ";;"),    options[0][0], ineg))
                            option_list.append("%s#define %s %d" % (("" if imul else ";;"),    options[1][0], imul))
                            option_list.append("%s#define %s %d" % (("" if ipred else ";;"),   options[2][0], ipred))
                            option_list.append("%s#define %s %d" % (("" if izloop else ";;"),  options[3][0], izloop))
                            option_list.append("%s#define %s %d" % (("" if idjnz else ";;"),   options[4][0], idjnz))
                            option_list.append("%s#define %s %d" % (("" if ipipe else ";;"),   options[5][0], ipipe))
                            option_list.append("%s#define %s %d" % (("" if ishift else ";;"),   options[6][0], ishift))
                            # UNROLL
                            if not iunroll:
                                option_list.append("#define NOUNROLL_UDIV 1")
                            elif iunroll == 2:
                                option_list.append("#define UNROLL_UDIV2 1")
                            elif iunroll == 4:
                                option_list.append("#define UNROLL_UDIV4 1")
                            with open (option_filename,"w") as fh:
                                fh.write( '\n'.join(option_list))
                            fh.close
    
                            with open ( "logs/%s.stats.csv" % filebase,"w") as fh:
                                for j in fixed_options:
                                    fh.write("%s,%d\n" % (j,fixed_options[j]))
                                fh.write("%s,%d\n" % (options[0][0], ineg))
                                fh.write("%s,%d\n" % (options[1][0], imul))
                                fh.write("%s,%d\n" % (options[2][0], ipred))
                                fh.write("%s,%d\n" % (options[3][0], izloop))
                                fh.write("%s,%d\n" % (options[4][0], idjnz))
                                fh.write("%s,%d\n" % (options[5][0], ipipe))
                                fh.write("%s,%d\n" % (options[6][0], ishift))                                
                            fh.close()
    
                            run_script.append("cp %s ../tests/options.h" % option_filename)
                            run_script.append("pushd ../tests")
                            run_script.append("make clean")
                            run_script.append("time make all -j %d" % MAX_CPUS)
                            run_script.append("popd")
                            run_script.append("make clean")
                            # setup the env var for the pipe stages for simulation
                            if ipipe == 2:
                                run_script.append("setenv PIPE_OPTION '-D TWO_STAGE_PIPE=1'")
                            else:
                                run_script.append("setenv PIPE_OPTION '-D THREE_STAGE_PIPE=1'")
                            if PI_ONLY:
                                run_script.append("time make pi-spigot-rev.sim ")
                                run_script.append("time make pi-spigot-rev.stdout ")
                                run_script.append("time make pi-spigot-rev.stats ")
                            else:
                                run_script.append("time make all -j %d" % MAX_CPUS)
                            run_script.append("cp pi-spigot-rev.stdout logs/%s_pi-spigot-rev.stdout  " % filebase)
                            run_script.append("cp e-spigot-rev.stdout logs/%s_e-spigot-rev.stdout  " % filebase)
                            run_script.append("head -5  nqueens.stdout > logs/%s_nqueens.stdout  " % filebase)
                            run_script.append("tail -3  nqueens.stdout >> logs/%s_nqueens.stdout  " % filebase)
                            run_script.append("foreach f ( `ls -1 *stats | grep -v '(djnz|test|bit)'`)")
                            run_script.append("  cat $f >> logs/%s.stats.csv" %(filebase))
                            run_script.append("end")
                            run_script.append("date")

run_script.append ( "cp logs/options.h_save ../tests/options.h")
with open( "run_script.csh", "w") as fh:
    fh.write('\n'.join(run_script))
fh.close()
