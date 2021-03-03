
#!/bin/csh -fv

SRCDIR=../rtl
TSTDIR=../tests
SRCS= $(wildcard $(SRCDIR)/*.v)
HDRS= $(wildcard $(SRCDIR)/*.vh)
TESTS= $(wildcard $(TSTDIR)/*.s)

testname ?= pi-spigot-rev

VPATH=${SRCDIR}:${TSTDIR}

${testname}.hex: ${testname}.s
	cd ${TSTDIR} && make all

test1.hex : ${testname}.hex
	cp ${TSTDIR}/${testname}.hex test1.hex

system_tb.exe: ${HDRS} ${SRCS} system_tb.v 
	iverilog -I${SRCDIR} -o system_tb.exe \
	   -D MEM_INIT_FILE_D="\"test1.hex\"" \
           -D VCD_FILE_D="\"test1.vcd\"" \
           -D RAM_DUMP_FILE_D="\"test1.dump\"" \
           system_tb.v \
           ${SRCDIR}/system.v \
           ${SRCDIR}/gpio.v \
           ${SRCDIR}/alu.v \
           ${SRCDIR}/grf1w2r.v \
           ${SRCDIR}/cpu_2432.v \
           ${SRCDIR}/rom_8192x24.v \
           ${SRCDIR}/ram_8192x32.v

test1.vcd: system_tb.exe test1.hex
	./system_tb.exe

all: ${testname}.hex test1.hex test1.vcd

clean:
	rm -f *.vcd *.exe *~ *dump
