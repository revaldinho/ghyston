SRCDIR=../rtl
TSTDIR=../tests
SRCS= $(wildcard $(SRCDIR)/*.v)
HDRS= $(wildcard $(SRCDIR)/*.vh)
TESTSRCS= $(wildcard $(TSTDIR)/*.s)
TESTHEXES= $(wildcard $(TSTDIR)/*.hex)
TESTNAMES = $(notdir ${TESTSRCS} )
TESTS= $(patsubst %.s,%.sim,$(TESTNAMES))
STDOUT= $(patsubst %.s,%.stdout,$(TESTNAMES))

VPATH=${SRCDIR}:${TSTDIR}

pyexec ?= python3

%.hex: %.s
	cd ${TSTDIR} && make $*.hex


# Only include this to get a full VCD dump
#           -D VCD_FILE_D="\"$*.vcd\"" \
#
%.exe: %.hex ${HDRS} ${SRCS} system_tb.v
	iverilog -I${SRCDIR} -o $*.exe \
	   -D MEM_INIT_FILE_D="\"${TSTDIR}/$*.hex\"" \
           -D RAM_DUMP_FILE_D="\"$*.dump\"" \
           system_tb.v \
           ${SRCDIR}/system.v \
           ${SRCDIR}/gpio.v \
           ${SRCDIR}/alu.v \
           ${SRCDIR}/grf1w2r.v \
           ${SRCDIR}/cpu_2432.v \
           ${SRCDIR}/rom_8192x24.v \
           ${SRCDIR}/ram_8192x32.v

%.stdout : %.sim
	cat $*.sim | pyexec ../tools/extract_stdout.py >  $*.stdout

%.sim %.vcd %.dump : %.exe
	./$*.exe > $*.sim

realclean:
	rm -f *.vcd *.exe *~ *dump *.sim *.hex *.stdout
	cd ${TSTDIR} && make clean
clean:
	rm -f *.vcd *.exe *~ *dump *.sim *.hex *.stdout

all: ${STDOUT}
