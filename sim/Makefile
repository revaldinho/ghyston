SRCDIR=../rtl
TSTDIR=../tests
SRCS= $(wildcard $(SRCDIR)/*.v)
HDRS= $(wildcard $(SRCDIR)/*.vh)
TESTSRCS= $(wildcard $(TSTDIR)/*.s)
TESTHEXES= $(wildcard $(TSTDIR)/*.code.hex)
TESTNAMES = $(notdir ${TESTSRCS} )
TESTS= $(patsubst %.s,%.sim,$(TESTNAMES))
STDOUT= $(patsubst %.s,%.stdout,$(TESTNAMES))
STATS = $(patsubst %.s,%.stats,$(TESTNAMES))
VPATH=${SRCDIR}:${TSTDIR}

pyexec ?= python3

%.code.hex: %.s ../tests/options.h ${TESTSRCS}
	cd ${TSTDIR} && make $*.code.hex


# Only include this to get a full VCD dump
#           -D VCD_FILE_D="\"$*.vcd\"" \
#
%.exe: %.code.hex %.data.hex ${HDRS} ${SRCS} system_tb.v
	iverilog -I${SRCDIR} -o $*.exe \
	   -D ROM_INIT_FILE_D="\"${TSTDIR}/$*.code.hex\"" \
	   -D RAM_INIT_FILE_D="\"${TSTDIR}/$*.data.hex\"" \
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
	cat $*.sim | ${pyexec} ../tools/extract_stdout.py >  $*.stdout

%.sim %.vcd %.dump : %.exe
	./$*.exe > $*.sim

%.stats : %.sim %.lst
	echo "filename,$*" > $*.stats
	egrep Assembled ../tests/$*.lst | awk '{print "Instr_words," $$2}' >> $*.stats
	tail -50 $*.sim | awk '/terminated/{ print "Cycles," $$5/1000} /Executed/{print "Instr_Executed,"$$2}' >> $*.stats

realclean:
	rm -f *.vcd *.exe *~ *dump *.sim *.hex *.stdout *stats
	cd ${TSTDIR} && make clean
clean:
	rm -f *.vcd *.exe *~ *dump *.sim *.hex *.stdout *stats

all: ${STDOUT} ${STATS} ${TESTS}
