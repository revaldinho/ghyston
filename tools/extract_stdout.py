
# Simple utility to extract STDOUT data from .sim files
#
# cat test.sim | python3 extract_stdout.py

import re
import sys

stdout_re = re.compile("(\s*)?STDOUT\s*:\s*Data\s:\s*0x(?P<hexdata>[0-9a-f]*)\s*\(\s*(?P<decdata>[0-9a-f]*)\).*")

for l in sys.stdin:
    m = stdout_re.match(l)
    if m:
        data = int(m.groupdict()["decdata"])
        # Suppress the CR characters 
        if data != 13:
            print("%c" % data, end="")
