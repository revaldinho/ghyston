#!/bin/csh -fv

SRCS = $(wildcard *.s)
HEXS  = $(patsubst %.s,%.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))

pyexec ?= python3
assembler ?= ../tools/asm_2432.py

%.hex %.lst : %.s
	${pyexec} ${assembler} -f $< -o $*.hex -z 8192 > $*.lst

all: ${HEXS}

clean:
	rm -f *.hex *.lst *~
