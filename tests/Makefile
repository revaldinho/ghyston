#!/bin/csh -fv

SRCS = $(wildcard *.s)
HEXS  = $(patsubst %.s,%.code.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))

INCDIR = include
VPATH=${INCDIR}
pyexec ?= python3
assembler ?= ../tools/asm_2432.py

# Use CPP on the .s file first to expand ifdefs
%.code.hex %.data.hex %.lst : %.s options.h macros.h intmath.s stdio.s stdlib.s
	filepp -d -ds -dpre ';' $< > $*.spp
	${pyexec} ${assembler} -f $*.spp -o $*.code.hex -d $*.data.hex -z 8192 > $*.lst
	rm $*.spp

all: ${HEXS}

clean:
	rm -f *.hex *.lst *~
