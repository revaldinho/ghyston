#
# Run this script from the sim/ area
#
import re
import sys
import os, os.path
import shutil

MAX_CPUS = 8
PI_ONLY = False


options = [
    ("MUL18X18",[0,1]),
    ("NEG_INSTR",[0,1]),
    ("ZLOOP_INSTR",[0,1]),
    ("DJNZ_INSTR",[0,1]),
    ("PIPE_STAGES",[2,3]),
    ("UNROLLUDIV_LOOP",[0,2,4])
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
for ii in (options[0])[1]:
    for jj in options[1][1]:
        for kk in options[2][1]:
            for ll in options[3][1]:
                for mm in options[4][1]:
                    for nn in options[5][1]:

                        option_list = []
                        run_script.append("# ------------------------------------------------------------")
                        run_script.append("# Run number %s"% run)
                        run +=1
                        option_list.append("------------------------------------------------------------")
                        filebase = "mul%d_neg%d_zloop%d_djnz%d_pipe%d_urol%d" %(ii,jj,kk,ll,mm,nn)                        
                        option_filename = ("options/%s.options.h" %(filebase))
                        option_list.append (";; %s" % option_filename)
                        option_list.append("------------------------------------------------------------")
                        option_list.append("%s#define %s %d" % (("" if ii else ";;"), options[0][0], ii))
                        option_list.append("%s#define %s %d" % (("" if jj else ";;"), options[1][0], jj))
                        option_list.append("%s#define %s %d" % (("" if kk else ";;"), options[2][0], kk))
                        option_list.append("%s#define %s %d" % (("" if ll else ";;"), options[3][0], ll))
                        option_list.append("%s#define %s %d" % (("" if mm else ";;"), options[4][0], mm))

                        # UNROLL
                        if not nn:
                            option_list.append("#define NOUNROLL_UDIV 1")
                        elif nn == 2:
                            option_list.append("#define UNROLL_UDIV2 1")
                        elif nn == 4:
                            option_list.append("#define UNROLL_UDIV4 1")
                        with open ( "logs/%s.stats.csv" % filebase,"w") as fh:
                            fh.write("%s,%d\n" % (options[0][0], ii))
                            fh.write("%s,%d\n" % (options[1][0], jj))
                            fh.write("%s,%d\n" % (options[2][0], kk))
                            fh.write("%s,%d\n" % (options[3][0], ll))
                            fh.write("%s,%d\n" % (options[4][0], mm))
                            fh.write("%s,%d\n" % (options[5][0], nn))
                        fh.close()
                        with open (option_filename,"w") as fh:
                            fh.write( '\n'.join(option_list))
                        fh.close
                        run_script.append("cp %s ../tests/options.h" % option_filename)
                        run_script.append("pushd ../tests")
                        run_script.append("make clean")
                        run_script.append("time make all -j %d" % MAX_CPUS)
                        run_script.append("popd")
                        run_script.append("make clean")
                        if PI_ONLY:
                            run_script.append("time make pi-spigot-rev.sim ")
                            run_script.append("time make pi-spigot-rev.stdout ")
                            run_script.append("time make pi-spigot-rev.stats ")
                        else:
                            run_script.append("time make all -j %d" % MAX_CPUS)
                        run_script.append("cp pi-spigot-rev.stdout logs/%s_pi-spigot-rev.stdout  " % filebase)                        
                        run_script.append("cat *stats | egrep -v '(djnz.s|bit.s|test.s)' >> logs/%s.stats.csv" %(filebase))
                        run_script.append("date")
run_script.append ( "cp logs/options.h_save ../tests/options.h")
with open( "run_script.csh", "w") as fh:
    fh.write('\n'.join(run_script))
fh.close()
