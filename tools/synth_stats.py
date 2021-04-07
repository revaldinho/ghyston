# synth_stats.py <dir> <no_header>

import os
import os.path
import re
import sys

dir = sys.argv[1]
no_header = False
if len(sys.argv)>2 and sys.argv[2]=="no_header":
    no_header = True

# Max Freq

build_stats = {}
max_freq_re = re.compile("\s*Minimum period:\s*(?P<period>\d*\.\d*)n.*\(Maximum frequency:\s*(?P<frequency>\d*\.\d*)MHz\)")

build_regexps = {
    "device_re":re.compile(".*device\s*(?P<device>\w.*?),.*speed\s*\-(?P<speed>\d*)"),
    "slice_registers_re":re.compile(".*Slice Registers\:\s*(?P<slice_registers>\d*[,\d]*)\s"),
    "slice_luts_re":re.compile(".*Slice LUTs\:\s*(?P<slice_LUTs>\d[,\d]*)\s"),
    "lut_memory_re":re.compile(".*Number used as Memory:\s*(?P<LUT_memory>\d*[,\d]*)\s"),
    "occupied_slices_re":re.compile(".*occupied Slices:\s*(?P<occupied_slices>\d*[,\d]*)\s"),
    "ramb16b_re":re.compile(".*?RAMB16BWERs\:\s*(?P<ramb16>\d*?)\s"),
    "ramb8b_re":re.compile(".*?RAMB8BWERs\:\s*(?P<ramb8>\d*?)\s"),
    "dsp_slices_re":re.compile(".*?DSP48A1s\:\s*(?P<dsp>\d*?)\s")
}

dirname_re = re.compile("pipe(?P<pipestages>\d)_(?P<shift31>s16_)?mul(?P<mul>\d)_zl(?P<zloop>\d)_(?:dj(_)?(?P<dj>\d)_)?(?:djz(?P<djz>\d)_)?(?:djm(?P<djm>\d)_)?neg(?P<neg>\d)(?:_abs(?P<abs>\d))?(?:_pred(?P<pred>\d))?.*")


options = { "shift31":"0" , "djm":"0", "djz":"0", "abs":"0", "pred":"0"}

m = dirname_re.match(dir)
if not m:
    print ("Directory name does not parse: %s" % dir )
    sys.exit(1)
else:
    gd = m.groupdict()
    for opt in gd:
        if gd[opt]:
            if opt=="shift31":
                options[opt]="1"
            elif opt == "dj" and gd[opt]=="1":
                options["djm"]="1"
                options["djz"]="1"
            else:
                options[opt]=gd[opt]


for source in ("best_system.twr","best_system.par"):
    f = os.path.join(dir,source)
    if not os.path.exists( f ) :
        print("Error: cannot find %s f i directory %s" % (source,dir) )
        sys.exit(1)
    else:
        with open (f,"r") as fh:
            if source == "best_system.twr":
                for l in fh:
                    m = max_freq_re.match(l)
                    if m:
                        gd = m.groupdict()
                        for stat in gd:
                            build_stats[stat] = gd[stat]
            else:
                for l in fh:
                    for r in build_regexps:
                        m = (build_regexps[r]).match(l)
                        if m:
                            gd = m.groupdict()
                            for stat in gd:
                                build_stats[stat] = gd[stat].replace(",",".")
                            next

        fh.close()

header = []
data = []


# Stick to a fixed order for the headings even though it means explicitly enumerating them here
okeys = "pipestages,mul,neg,shift31,zloop,djz,djm,abs,pred".split(",")
bkeys = "device,speed,frequency,period,occupied_slices,slice_registers,slice_LUTs,LUT_memory,ramb16,ramb8,dsp".split(',')

for k in okeys:
    header.append(k)
    data.append(options[k])
for s in bkeys:
    header.append(s)
    data.append(build_stats[s])

if not no_header:
    print ( ','.join(header))
print ( ','.join(data))
