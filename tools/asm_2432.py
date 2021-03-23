#!/usr/bin/env python3
## ============================================================================
## asm_2432.py - word oriented assembler for the 2432 CPU
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## See  <http://www.gnu.org/licenses/> for a copy of the GNU Lesser General
## Public License
##
## ============================================================================
'''
USAGE:

  asm_2432 is an assembler for the 2432 CPU

REQUIRED SWITCHES ::

  -f --filename  <filename>      specify the assembler source file

OPTIONAL SWITCHES ::

  -o --output    <filename>      specify file name for assembled code

  -d --data      <filename>      specify file name for data segment
                                 - if not supplied data will use the same filename
                                   as the code, but with a .data suffix

  -g --format    <bin|hex>       set the file format for the assembled code
                                 - default is hex

  -n --nolisting                 suppress the listing to stdout while the
                                 program runs

  -s, --start_adr                sets the number of the first byte to be written
                                 out (must be even)

  -z, --size                     sets the number of bytes to be written out (must
                                 be even)

  -h --help                      print this help message

  If no output filename is provided the assembler just produces the normal
  listing output to stdout.

EXAMPLES ::

  python3 asm_2432.py -f test.s -o test.bin -g bin
'''

header_text = '''
# -----------------------------------------------------------------------------
# G h y s t o n - 2 4 3 2  * A S S E M B L E R
# -----------------------------------------------------------------------------
#
# ADDRESS : CODE   : SOURCE
#---------:--------:-----------------------------------------------------------
'''

import sys, re, codecs, getopt, shlex

# globals
(errors, warnings, nextmnum, debug) = ( [],[],0, False)

cond_codes = {
    "eq": 0x0, ## equal
    "z":  0x0, ## equal
    "ne": 0x1, ## not equal
    "nz": 0x1, ## not equal
    "cs": 0x2, ## unsigned higher or same (or carry set).
    "c":  0x2, ## unsigned higher or same (or carry set).
    "cc": 0x3, ## unsigned lower (or carry clear).
    "nc": 0x3, ## unsigned lower (or carry clear).
    "mi": 0x4, ## negative. the mnemonic stands for "minus".
    "pl": 0x5, ## positive or zero. the mnemonic stands for "plus".
    "vs": 0x6, ## signed overflow. the mnemonic stands for "v set".
    "v":  0x6, ## signed overflow. the mnemonic stands for "v set".
    "vc": 0x7, ## no signed overflow. the mnemonic stands for "v clear".
    "nv": 0x7, ## no signed overflow. the mnemonic stands for "v clear".
    "hi": 0x8, ## unsigned higher.
    "ls": 0x9, ## unsigned lower or same.
    "ge": 0xa, ## signed greater than or equal.
    "lt": 0xb, ## signed less than.
    "gt": 0xc, ## signed greater than.
    "le": 0xd, ## signed less than or equal.
    "al": 0xf  ## always - unconditional
}

##  Generally only even opcodes are listed - odd versions select an immediate rather than second source reg
op = {
    "spare3"    : {"format":"a", "opcode": 0 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "spare4"    : {"format":"a", "opcode": 2 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "ldw"       : {"format":"a", "opcode": 4 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "ld.w"      : {"format":"a", "opcode": 4 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "ld"        : {"format":"a", "opcode": 4 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "mov"       : {"format":"a", "opcode": 6 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
# Alternate form of neg uses only one opcode
#    "neg"     : {"format":"a", "opcode": 7 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "spare1"   : {"format":"b", "opcode": 8 , "sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "spare2"   : {"format":"b", "opcode": 10 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "stw"      : {"format":"b", "opcode": 12 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "sto.w"      : {"format":"b", "opcode": 12 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
    "sto"      : {"format":"b", "opcode": 12 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":16383},
#   ""        : {"format":"b", "opcode": 14 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":0},
    "jr"       : {"format":"c", "opcode": 16 ,"sext":False, "cond":True,  "operands":2, "sext": False, "min_imm":-512, "max_imm":511}, # COND field is optional in source code
    # Ret is a synonmym for JR AL RLINK,0
    "ret"     : {"format":"c", "opcode": 17 ,"sext":False, "cond":True,  "operands":2, "sext": False, "min_imm":0,    "max_imm":0},
    "bra"     : {"format":"c", "opcode": 16 ,"sext":False, "cond":True,  "operands":1, "sext": False, "min_imm":-512, "max_imm":511},
    "bcc"     : {"format":"c", "opcode": 16 ,"sext":False, "cond":True,  "operands":1, "sext": False, "min_imm":-512, "max_imm":511},
    "jrsr"    : {"format":"c", "opcode": 18 ,"sext":False, "cond":True,  "operands":2, "sext": False, "min_imm":-512, "max_imm":511},
    "bsr"     : {"format":"c", "opcode": 18 ,"sext":False, "cond":True,  "operands":1, "sext": False, "min_imm":-512, "max_imm":511},
    "djnz"    : {"format":"c", "opcode": 21 ,"sext":True,  "cond":True,  "operands":3, "sext": False, "min_imm":-512, "max_imm":511},
    "jmp"     : {"format":"c2","opcode": 22 ,"sext":False, "cond":False, "operands":1, "sext": False, "min_imm":0,    "max_imm":262143},
    "jsr"     : {"format":"c2","opcode": 23 ,"sext":False, "cond":False, "operands":1, "sext": False, "min_imm":0,    "max_imm":262143},
    ## Next two opcodes take up 4 opcodes each, with 2 LSBs used as additional immediate bits
    "movi"    : {"format":"d", "opcode": 24 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":65535},
    "movti"   : {"format":"d", "opcode": 28 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":65535},
    "and"     : {"format":"e", "opcode": 32 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "or"      : {"format":"e", "opcode": 34, "sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "xor"     : {"format":"e", "opcode": 36 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "mul"     : {"format":"e", "opcode": 38 ,"sext":True,  "cond":False, "operands":3, "sext": True,  "min_imm":-512, "max_imm":511},
    "add"     : {"format":"e", "opcode": 40 ,"sext":True,  "cond":False, "operands":3, "sext": True,  "min_imm":-512, "max_imm":511},
    "sub"     : {"format":"e", "opcode": 42 ,"sext":True,  "cond":False, "operands":3, "sext": True,  "min_imm":-512, "max_imm":511},
    "asr"     : {"format":"e", "opcode": 44 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "lsr"     : {"format":"e", "opcode": 46 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "ror"     : {"format":"e", "opcode": 48 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "asl"     : {"format":"e", "opcode": 50 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "rol"     : {"format":"e", "opcode": 52 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":1023},
    "bset"    : {"format":"e", "opcode": 54 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":31},
    "bclr"    : {"format":"e", "opcode": 56 ,"sext":False, "cond":False, "operands":3, "sext": False, "min_imm":0,    "max_imm":31},
    "btst"    : {"format":"e", "opcode": 58 ,"sext":False, "cond":False, "operands":2, "sext": False, "min_imm":0,    "max_imm":31},
    "cmp"     : {"format":"e", "opcode": 60 ,"sext":True,  "cond":False, "operands":2, "sext": True,  "min_imm":-512, "max_imm":511},
    "neg"     : {"format":"e", "opcode": 62 ,"sext":True,  "cond":False, "operands":2, "sext": True,  "min_imm":-512, "max_imm":511},
}


def usage():
    print (__doc__);
    sys.exit(1)

def is_register( word ):
    return ( re.match( "(r\d(\d)?)|(psr)|(pc)", word, re.IGNORECASE ))

def expand_macro(line, macro, mnum):  # recursively expand macros, passing on instances not (yet) defined
    global nextmnum
    (text,mobj)=([line],re.match("^(?P<label>\w*\:)?\s*(?P<name>\w+)\s*?\((?P<params>.*?)\)",line))
    if mobj and mobj.groupdict()["name"] in macro:
        (label,instname,paramstr)= (mobj.groupdict()["label"],mobj.groupdict()["name"],mobj.groupdict()["params"])
        (text, instparams,mnum,nextmnum) = ([";%s" % line], [x.strip() for x in paramstr.split(",")],nextmnum,nextmnum+1)
        if label:
            text.append("%s%s"% (label, ":" if (label != "" and label != "None" and not (label.endswith(":"))) else ""))
        for newline in macro[instname][1]:
            for (s,r) in zip( macro[instname][0], instparams):
                newline = (newline.replace(s,r) if s else newline).replace('@','%s_%s' % (instname,mnum))
            text.extend(expand_macro(newline, macro, nextmnum))
    return(text)

def preprocess( filename ) :
    # Pass 0 - read file, expand all macros and return a new text file
    global errors, warnings, nextmnum
    (newtext,macro,macroname,mnum)=([],dict(),None,0)
    for line in open(filename, "r").readlines():
        mobj =  re.match("\s*?MACRO\s*(?P<name>\w*)\s*?\((?P<params>.*)\)", line, re.IGNORECASE)
        if mobj:
            (macroname,macro[macroname])=(mobj.groupdict()["name"],([x.strip() for x in (mobj.groupdict()["params"]).split(",")],[]))
        elif re.match("\s*?ENDMACRO.*", line, re.IGNORECASE):
            (macroname, line) = (None, '; ' + line)
        elif macroname:
            macro[macroname][1].append(line)
        newtext.extend(expand_macro(('' if not macroname else '; ') + line, macro, mnum))
    return newtext

def assemble( filename, listingon=True):
    global errors, warnings, nextmnum
    symtab = dict( [ ("r%d"%d,d) for d in range(0,16)] + [("pc",15), ("psr",0)])
    reg_re = re.compile("(r\d*|psr|pc)")
    (codemem,code_count)=([0x00000000]*256*1024,0)
    (datamem,data_count)=([0x00000000]*256*1024,0)

    newtext = preprocess(filename)

    for iteration in range (0,2): # Two pass assembly
        mode = "CODE"
        (code_count,nextimem, data_count, nextdmem) = (0,0,0,0)
        for line in newtext:
            mobj = re.match('^(?:(?P<label>\w+)\:)?(\s*)?(?P<inst>\w[\w\.]+)?\s*(?P<operands>.*)',re.sub("(;.*|#.*)","",line))
            (label, inst, operands) = [ mobj.groupdict()[item] for item in ("label", "inst","operands")]
            (opfields,words, memptr, dmemptr) = ([ x.strip() for x in operands.split(",")],[], nextimem, nextdmem)
            if (iteration==0 and (label and label != "None") or (inst=="EQU")):
                errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in symtab else errors
                try:
                    if mode == "CODE":
                        exec ("%s= int(%s)" % ((label,str(nextimem)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
                    else:
                        exec ("%s= int(%s)" % ((label,str(nextdmem)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
                except:
                    errors += [ "Syntax error on:\n  %s" % line.strip() ]
                    continue
            if (inst in("WORD","HALF","BYTE") or inst in op) and iteration < 1:
                if mode == "CODE":
                    if not (inst in op):
                        warnings.append("Warning: assembling data into CODE section ...\n         %s" % (line.strip()))
                    if inst=="WORD":
                        nextimem += len(opfields)
                    elif inst == "HALF":
                        nextimem += (len(opfields)+1)//2
                    elif inst == "BYTE":
                        nextimem += (len(opfields)+3)//4
                    else:
                        nextimem += 1
                else:
                    if inst=="WORD":
                        nextdmem += len(opfields)
                    elif inst == "HALF":
                        nextdmem += (len(opfields)+1)//2
                    elif inst == "BYTE":
                        nextdmem += (len(opfields)+3)//4
                    else:
                        warnings.append("Warning: assembling code into DATA section ...\n         %s" % (line.strip()))
                        nextdmem += 1

            elif inst in ("BYTE","HALF","WORD","STRING","BSTRING","PBSTRING"):
                if mode == "CODE":
                    warnings.append("Warning: assembling data into CODE section ...\n         %s" % (line.strip()))
                if  inst in("STRING","BSTRING","PBSTRING"):
                    strings = re.match('.*STRING\s*\"(.*?)\"(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?.*?', line.rstrip())
                    string_data = codecs.decode(''.join([ x for x in strings.groups() if x != None]),  'unicode_escape')
                    string_len = chr(len( string_data ) & 0xFF) if inst=="PBSTRING" else ''    # limit string length to 255 for PBSTRINGS
                    if inst in ("BSTRING","PBSTRING") :
                        wordstr =  string_len + string_data + chr(0) + chr(0) + chr(0)
                        words = [(ord(wordstr[i])|(ord(wordstr[i+1])<<8)|(ord(wordstr[i+2])<<16)|(ord(wordstr[i+3])<<24)) for  i in range(0,len(wordstr)-3,4) ]
                    else:
                        wordstr = string_len + string_data
                        words = [ord(wordstr[i]) for  i in range(0,len(wordstr))]
                else:
                    try:
                        if mode == "CODE":
                            exec("PC=%d+1" % nextimem, globals(), symtab) # calculate PC as it will be in EXEC state
                        if inst == "BYTE":
                            words = [int(eval( f,globals(), symtab)) for f in opfields ] + [0]*3
                            words = ([(words[i+3]&0xFF)<<24|(words[i+2]&0xFF)<<16|(words[i+1]&0xFF)<<8|(words[i]&0xFF) for i in range(0,len(words)-3,4)])
                        elif inst == "HALF":
                            words = [int(eval( f,globals(), symtab)) for f in opfields ] + [0]
                            words = ([(words[i+1]&0xFFFF)<<16|(words[i]&0xFFFF) for i in range(0,len(words)-1,2)]) if inst=="HALF" else words
                        else :
                            words = [int(eval( f,globals(), symtab)) for f in opfields ]
                    except (ValueError, NameError, TypeError,SyntaxError):
                        (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
                if mode == "CODE":
                    (codemem[nextimem:nextimem+len(words)], nextimem,code_count )  = (words, nextimem+len(words),code_count+len(words))
                else:
                    (datamem[nextdmem:nextdmem+len(words)], nextdmem,data_count )  = (words, nextdmem+len(words),data_count+len(words))
            elif inst in op:
                # Check if the first of the opfields has a space separated condition code and extract it if it does
                condfield = "al"
                if ( op[inst]["cond"] and len(opfields)>0):
                    tmp = opfields[0].split()
                    if len(tmp) > 1:
                        condfield = tmp[0]
                        opfields[0] = tmp[1]

                direct=False
                if len(opfields) > 0 and not opfields[0]=='':
                    if ( not is_register(opfields[-1])):
                        direct=True
                    try:
                        words = [int(eval( f,globals(), symtab)) for f in opfields ]
                    except:
                        (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
                else:
                    words = []

                # deal with RET synonym for JR CC Rlink,1
                if inst in ("ret" ):
                    if len(opfields) == 0:
                        opfields.append("r14")
                        words.append(14)
                        opfields.append("0")
                        words.append(0)
                    elif len(opfields) == 1 and (opfields[0]==''):
                        opfields[0] = "r14"
                        words.append(14)
                        opfields.append("0")
                        words.append(0)
                    elif len(opfields) == 1:
                        opfields.append("0")
                        words.append(0)
                if inst == "mov" and not is_register(opfields[-1]):
                    inst = "movi"
                if ( op[inst]["operands"] != len(words)):
                    errors.append("Error: wrong number of operands for instruction %s\n on line %s" % (inst, line.strip()))
                else:
                    (rdest, cond, rsrc1, rsrc2, imm) = (0,0,0,0,0)
                    opcode = op[inst]["opcode"]
                    ifmt = op[inst]["format"]
                    # Format A - load instructions and register move
                    # Format B - store instructions
                    if ifmt == "a" or ifmt == "b":
                        if ifmt=="a":
                            rdest = words[0]
                            if (inst in ("not")):
                                direct = 0
                        else:
                            rsrc1 = words[0]
                        if (direct):
                            imm = words[1]
                        else:
                            rsrc2 = words[1]
                    # Format C - branch and return instructions
                    elif ifmt == "c":
                        if ( inst == "djnz" ) :
                            cond = 0
                            imm = words[2] - (nextimem)
                            rdest = words[0]
                            rsrc1 = words[1]
                        else:
                            cond = cond_codes[condfield]
                            if (inst in ("bra","bsr","bcc")):
                                rsrc1 = 15 # PC
                                if (direct):
                                    # Branch to a label
                                    imm = words[0] - (nextimem)
                                else:
                                    rsrc2 = words[0]
                            else:
                                rsrc1 = words[0]
                                if (direct):
                                    imm = words[1]
                                else:
                                    rsrc2 = words[1]
                    # Format C2 - Jump instructions
                    elif ifmt == "c2":
                        imm = words[0]
                        # Use the whole instruction so blank out the direct bit
                        direct = 0
                    # Format D - Long mov/movt
                    elif ifmt == "d":
                        rdest = words[0]
                        imm = words[1]
                    # Format E - arith and logic instructions
                    elif ifmt == "e":
                        if inst in( "cmp", "btst") :
                            words.insert(0,0)
                        elif inst=="neg":
                            words.insert(1,0)
                        rdest = words[0]
                        rsrc1 = words[1]
                        if (direct):
                            imm = words[2]
                        else:
                            rsrc2 = words[2]

                    if (debug):
                        print (inst)
                        print ("opcode = %s" % op[inst]["opcode"])
                        print ("direct = %d" % direct)
                        print ("format = %s" % ifmt)
                        print ("rdest = %s" % rdest)
                        print ("rsrc1 = %s" % rsrc1)
                        print ("rsrc2 = %s" % rsrc2)
                        print ("cond = %d" % cond)
                        print ("imm   = %05x (%d)" % (imm,imm))

                    if ( not (op[inst]["min_imm"] <= imm <= op[inst]["max_imm"]) ):
                        errors.append("Error: immediate %d out of range (%d to %d) \n on line %s" % (imm, op[inst]["min_imm"], op[inst]["max_imm"], line.strip()))

                    # Break up immediate for recoding in segments
                    imm30    = ((imm & 0b00000000000000001111)      )
                    imm54    = ((imm & 0b00000000000000110000) >> 4 )
                    imm96    = ((imm & 0b00000000001111000000) >> 6 )
                    imm1310  = ((imm & 0b00000011110000000000) >> 10)
                    imm1514  = ((imm & 0b00001100000000000000) >> 14)
                    imm1714  = ((imm & 0b00111100000000000000) >> 14)

                    # Populate standard fields first
                    iword = (op[inst]["opcode"]<<18)| ((rdest | cond ) << 12) | ((rsrc1 ) << 8) | ((rsrc2 ) << 4) | imm30
                    # Now fit in immediate segments
                    if ifmt == "a" and direct:
                        iword  = iword | (imm54<<16) | (imm1310<<8) | (imm96<<4)| (1<<18 if direct else 0)
                    elif ifmt == "b" and direct:
                        iword  = iword | (imm54<<16) | (imm1310<<12) | (imm96<<4)| (1<<18 if direct else 0)
                    elif ifmt == "c" and direct:
                        iword  = iword | (imm54<<16) | (imm96<<4) | (1<<18 if direct else 0)
                    elif ifmt == "c2" :
                        iword  = iword | (imm54<<16) | (imm1714 << 12) | (imm1310<<8) | (imm96<<4)
                    elif ifmt == "d" :
                        iword  = iword | (imm54<<16) | (imm1514 << 18) | (imm1310<<8) | (imm96<<4)
                    elif ifmt == "e" and direct:
                        iword  = iword | (imm54<<16) | (imm96<<4) | (1<<18 if direct else 0)

                    words=[ iword ]
                    if mode == "CODE":
                        (codemem[nextimem:nextimem+len(words)], nextimem,code_count )  = (words, nextimem+len(words),code_count+len(words))
                        exec("PC=%d+%d" % (nextimem,len(opfields)-1), globals(), symtab) # calculate PC as it will be in EXEC state
                    else:
                        (datamem[nextdmem:nextdmem+len(words)], nextdmem,data_count )  = (words, nextdmem+len(words),data_count+len(words))
            elif inst == "ORG":
                if mode == "CODE":
                    oldimem = nextimem
                    nextimem = eval(operands,globals(),symtab)
                    if oldimem > nextimem:
                        warnings.append("Warning: ORG directive is setting code pointer lower than current value...\n         %s" % (line.strip()))
                else:
                    olddmem = nextdmem
                    nextdmem = eval(operands,globals(),symtab)
                    if olddmem > nextdmem:
                        warnings.append("Warning: ORG directive is setting data pointer lower than current value...\n         %s" % (line.strip()))
            elif inst == "CODE":
                mode = "CODE"
            elif inst == "DATA":
                mode = "DATA"
                ## If provided with an argument then reserve the amount of space requested
                if len(operands) > 0:
                    nextdmem += eval(operands,globals(),symtab)
            elif inst in ("WORDALIGN", "WALIGN","ALIGN"):
                if mode == "CODE":
                    while ( nextimem % 4 ) :
                        nextimem += 1
                else :
                    while ( nextdmem % 4 ) :
                        nextdmem += 1
            elif inst and (inst != "EQU") and iteration>0 :
                errors.append("Error: unrecognized instruction or macro %s in ...\n         %s" % (inst,line.strip()))
            if iteration > 0 and listingon==True:
                if mode == "CODE":
                    print("%08x C  %-8s  %s"%(memptr,' '.join([("%06x" % i) for i in words]),line.rstrip()))
                else:
                    if len(words) < 3 :
                        print("%08x D  %-8s  %s"%(dmemptr,' '.join([("%08x" % i) for i in words]),line.rstrip()))
                    else:
                        print("%08x D  %-8s %s"%(dmemptr,' '.join([("%08x" % i) for i in words[0:2]]),line.strip()))
                        for idx in range (2, len(words), 2):
                              print("%08x D  %-8s"%(dmemptr+(idx*2-2),' '.join([("%08x" % i) for i in words[idx:]])))

    print ("\nAssembled %5d words of code with %d error%s and %d warning%s." % (code_count,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
    print ("          %5d words of data" % (data_count))
    print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%08X (%08d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d|r\d\d|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))
    return (codemem, datamem)


if __name__ == "__main__":
    """
    Command line option parsing.
    """
    filename = ""
    hexfile = ""
    output_filename = ""
    data_filename = ""
    output_format = "hex"
    listingon = True
    start_adr = 0
    size = 0
    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:o:d:g:s:z:hn", ["filename=","output=","data=","format=","start_adr=","size=", "help","nolisting"])
    except getopt.GetoptError as  err:
        print(err)
        usage()

    if len(args)>=1:
        filename = args[0]
    if len(args)>1:
        output_filename = args[1]
        output_format = "hex"

    data_filename = ""

    for opt, arg in opts:
        if opt in ( "-f", "--filename" ) :
            filename = arg
        elif opt in ( "-d", "--data" ) :
            data_filename = arg
        elif opt in ( "-o", "--output" ) :
            output_filename = arg
        elif opt in ( "-s", "--start_adr" ) :
            start_adr = int(arg,0)
        elif opt in ( "-z", "--size" ) :
            size = int(arg,0)
        elif opt in ( "-g", "--format" ) :
            if (arg in ("hex", "bin")):
                output_format = arg
            else:
                usage()
        elif opt in ("-n", "--nolisting"):
            listingon = False
        elif opt in ("-h", "--help" ) :
            usage()
        else:
            sys.exit(1)

    if filename != "":

        if size==0:
            size = 256*1024 - start_adr
        print(header_text)
        (codemem, datamem)  = assemble(filename, listingon)[start_adr:start_adr+size]
        if len(errors)==0 and output_filename != "":
            if data_filename == "" :
                data_filename = "%s.data" % output_filename
            if output_format == "hex":
                with open(output_filename,"w" ) as f:
                    f.write( '\n'.join([''.join("%08x " % d for d in codemem[j:j+12]) for j in [i for i in range(0,len(codemem),12)]]))
                with open(data_filename,"w" ) as f:
                    f.write( '\n'.join([''.join("%08x " % d for d in datamem[j:j+12]) for j in [i for i in range(0,len(datamem),12)]]))
            else:
                with open(output_filename,"wb" ) as f:
                    # Write binary in little endian order
                    for w in codemem:
                        bytes = bytearray()
                        bytes.append( w & 0xFF)
                        bytes.append( (w>>8) & 0xFF)
                        bytes.append( (w>>16) & 0xFF)
                        #bytes.append( (w>>24) & 0xFF)
                        f.write(bytes)
                with open(data_filename,"wb" ) as f:
                    # Write binary in little endian order
                    for w in datamem:
                        bytes = bytearray()
                        bytes.append( w & 0xFF)
                        bytes.append( (w>>8) & 0xFF)
                        bytes.append( (w>>16) & 0xFF)
                        #bytes.append( (w>>24) & 0xFF)
                        f.write(bytes)
    else:
        usage()
    sys.exit( len(errors)>0)
