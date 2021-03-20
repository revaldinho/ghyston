#!/bin/csh -fv

SRCS = $(wildcard *.s)
HEXS  = $(patsubst %.s,%.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))

pyexec ?= python3
assembler ?= ../tools/asm_2432.py

# Use CPP on the .s file first to expand ifdefs
%.hex %.lst : %.s options.h macros.h
	filepp -d -ds -dpre ';' $< > $*.spp
	${pyexec} ${assembler} -f $*.spp -o $*.hex -z 8192 > $*.lst
	rm $*.spp

all: ${HEXS}

clean:
	rm -f *.hex *.lst *~
