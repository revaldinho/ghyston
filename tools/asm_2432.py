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

import sys, re, codecs, getopt

# globals
(errors, warnings, nextmnum, debug) = ( [],[],0, False)

cond_codes = {
    "eq": 0x0, ## equal
    "z": 0x0,  ## equal
    "ne": 0x1, ## not equal
    "nz": 0x1, ## not equal
    "cs": 0x2, ## unsigned higher or same (or carry set).
    "c": 0x2,  ## unsigned higher or same (or carry set).
    "cc": 0x3, ## unsigned lower (or carry clear).
    "nc": 0x3, ## unsigned lower (or carry clear).
    "mi": 0x4, ## negative. the mnemonic stands for "minus".
    "pl": 0x5, ## positive or zero. the mnemonic stands for "plus".
    "vs": 0x6, ## signed overflow. the mnemonic stands for "v set".
    "v": 0x6,  ## signed overflow. the mnemonic stands for "v set".
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

instr_format = {
    "a":    {"imm_lo":-512, "imm_hi":511,      "sign_ext":True, "min_op": 2, "max_op": 3,},    # Mnemonic Rd,       [Rs|Imm| Rs, Imm]
    "a1.1": {"imm_lo":-512, "imm_hi":511,      "sign_ext":True,  "min_op": 1, "max_op": 1,},    # Mnemonic <PC> [CC] [Rs|Imm| Rs, Imm]
    "a1.2": {"imm_lo":-512, "imm_hi":511,      "sign_ext":True,  "min_op": 2, "max_op": 2,},    # Mnemonic <PC>      [Rs|Imm| Rs, Imm]
    "a1.3": {"imm_lo":-512, "imm_hi":511,      "sign_ext":True,  "min_op": 2, "max_op": 2,},    # Mnemonic <PC>      [Rs|Imm| Rs, Imm]
    "a2":   {"imm_lo":-512, "imm_hi":511,      "sign_ext":True,  "min_op": 2, "max_op": 2,},    # Mnemonic CC        [Rs|Imm| Rs, Imm]
    "b":    {"imm_lo":0,    "imm_hi":255,      "sign_ext":False, "min_op": 3, "max_op": 4,},    # Mnemonic Rd,  Rs,  [Rs|Imm| Rs, Imm]
    "b1":   {"imm_lo":-128, "imm_hi":127,      "sign_ext":True,  "min_op": 3, "max_op": 4,},    # Mnemonic Rd,  Rs,  [Rs|Imm| Rs, Imm]
    "c":    {"imm_lo":0,    "imm_hi":63,       "sign_ext":False, "min_op": 3, "max_op": 4,},    # Mnemonic Rd,  Rs,  [Rs|Imm| Rs, Imm]
    "d":    {"imm_lo":0,    "imm_hi":1048575,  "sign_ext":False, "min_op": 1, "max_op": 1,},    # Mnemonic               Imm
    "e":    {"imm_lo":0,    "imm_hi":65535,    "sign_ext":False, "min_op": 2, "max_op": 2,}     # Mnemonic Rd,           Imm
    }

op = {
        # Mnemonic :    Expanded  ## Operand fields
        #          :    Opcode    ##
	"ld.b"	   : { "opcode": 0b000000, "instr_format":"a"},
	"ld.h"	   : { "opcode": 0b000001, "instr_format":"a"},
	"ld.w"	   : { "opcode": 0b000010, "instr_format":"a"},
	"ld"	   : { "opcode": 0b000010, "instr_format":"a"},
	"sto.b"	   : { "opcode": 0b000011, "instr_format":"a"},
	"sto.h"	   : { "opcode": 0b000100, "instr_format":"a"},
	"sto.w"	   : { "opcode": 0b000101, "instr_format":"a"},
	"sto"	   : { "opcode": 0b000101, "instr_format":"a"},
	"bra"	   : { "opcode": 0b000110, "instr_format":"a1.1"},
	"bcc"	   : { "opcode": 0b000110, "instr_format":"a1.1"},
	"jr"	   : { "opcode": 0b000110, "instr_format":"a1.2"},
	"jrcc"	   : { "opcode": 0b000110, "instr_format":"a1.2"},
	"jsrcc"    : { "opcode": 0b000111, "instr_format":"a2"},
	"and"	   : { "opcode": 0b100000, "instr_format":"b"},
	"or"	   : { "opcode": 0b100001, "instr_format":"b"},
	"xor"	   : { "opcode": 0b100010, "instr_format":"b"},
	"mul"	   : { "opcode": 0b100011, "instr_format":"b"},
	"ret"	   : { "opcode": 0b100100, "instr_format":"b"},
	"reti"	   : { "opcode": 0b100101, "instr_format":"b"},
	"add"	   : { "opcode": 0b100110, "instr_format":"b"},
	"sub"	   : { "opcode": 0b100111, "instr_format":"b"},
	"asr"	   : { "opcode": 0b001000, "instr_format":"c"},
	"lsr"	   : { "opcode": 0b001001, "instr_format":"c"},
	"bset"	   : { "opcode": 0b001010, "instr_format":"c"},
	"bclr"	   : { "opcode": 0b001011, "instr_format":"c"},
	"btst"	   : { "opcode": 0b001100, "instr_format":"c"},
	"ror"	   : { "opcode": 0b001101, "instr_format":"c"},
	"asl"	   : { "opcode": 0b001110, "instr_format":"c"},
	"rol"	   : { "opcode": 0b001111, "instr_format":"c"},
	"jmp"	   : { "opcode": 0b010000, "instr_format":"d"},
	"call"	   : { "opcode": 0b010100, "instr_format":"d"},
	"movi"	   : { "opcode": 0b011000, "instr_format":"e"},
	"movti"	   : { "opcode": 0b011100, "instr_format":"e"},
    }


def usage():
    print (__doc__);
    sys.exit(1)

def is_register( word ):
    return ( re.match( "(r\d)|(psr)|(pc)", word, re.IGNORECASE ))


def expand_macro(line, macro, mnum):  # recursively expand macros, passing on instances not (yet) defined
    global nextmnum
    (text,mobj)=([line],re.match("^(?P<label>\w*\:)?\s*(?P<name>\w+)\s*?\((?P<params>.*?)\)",line))
    if mobj and mobj.groupdict()["name"] in macro:
        (label,instname,paramstr)= (mobj.groupdict()["label"],mobj.groupdict()["name"],mobj.groupdict()["params"])
        (text, instparams,mnum,nextmnum) = (["#%s" % line], [x.strip() for x in paramstr.split(",")],nextmnum,nextmnum+1)
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
            (macroname, line) = (None, '# ' + line)
        elif macroname:
            macro[macroname][1].append(line)
        newtext.extend(expand_macro(('' if not macroname else '# ') + line, macro, mnum))
    return newtext

def assemble( filename, listingon=True):
    global errors, warnings, nextmnum

    symtab = dict( [ ("r%d"%d,d) for d in range(0,16)] + [("pc",15), ("psr",0)])
    reg_re = re.compile("(r\d*|psr|pc)")
    (wordmem,wcount)=([0x00000000]*1024*1024,0)

    newtext = preprocess(filename)

    for iteration in range (0,2): # Two pass assembly
        (wcount,nextmem) = (0,0)
        for line in newtext:
            mobj = re.match('^(?:(?P<label>\w+)\:)?(\s*)?(?P<inst>\w[\w\.]+)?\s*(?P<operands>.*)',re.sub("#.*","",line))
            (label, inst, operands) = [ mobj.groupdict()[item] for item in ("label", "inst","operands")]
            (opfields,words, memptr) = ([ x.strip() for x in operands.split(",")],[], nextmem)
            if (iteration==0 and (label and label != "None") or (inst=="EQU")):
                errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in symtab else errors
                try:
                    exec ("%s= int(%s)" % ((label,str(nextmem)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
                except:
                    errors += [ "Syntax error on:\n  %s" % line.strip() ]
                    continue
            if (inst in("WORD","HALF","BYTE") or inst in op) and iteration < 1:
                if inst=="WORD":
                    nextmem += len(opfields)
                elif inst == "HALF":
                    nextmem += (len(opfields)+1)//2
                elif inst == "BYTE":
                    nextmem += (len(opfields)+3)//4
                else:
                    nextmem += 1
            elif inst in ("BYTE","HALF","WORD","STRING","BSTRING","PBSTRING"):
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
                        exec("PC=%d+1" % nextmem, globals(), symtab) # calculate PC as it will be in EXEC state
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
                    (wordmem[nextmem:nextmem+len(words)], nextmem,wcount )  = (words, nextmem+len(words),wcount+len(words))
            elif inst in op:
                # Check if the first of the opfields has a space separated condition code and extract it if it does
                condfield = "al"
                if len(opfields)>0:
                    tmp = opfields[0].split(" ")
                    if len(tmp) > 1:
                        condfield = tmp[0]
                        opfields[0] = tmp[1]
                words = [int(eval( f,globals(), symtab)) for f in opfields ]

                ifmt = op[inst]["instr_format"]
                if ( not ( instr_format[ifmt]["min_op"] <= len(words) <= instr_format[ifmt]["max_op"] )):
                    errors.append("Error: wrong number of operands for instruction %s\n on line %s" % (inst, line.strip()))
                else:
                    imm = 0
                    rdest = 0
                    cond = 0
                    rsrc1 = 0
                    rsrc2 = 0
                    imm = 0
                    imm76 = 0
                    imm1514 = 0
                    imm1916 = 0
                    imm96 = 0
                    imm1310 = 0
                    imm50 = 0
                    opcode = op[inst]["opcode"]
                    
                    # Format A - load/store instructions
                    if ifmt == "a":
                        rdest = words[0]
                        if len(words) > 2:
                            rsrc2 = words[1]
                            imm = words[2]
                        elif is_register(opfields[1]):
                            rsrc2 = words[1]
                        else:
                            imm = words[1]
                            rsrc1 = imm
                            imm = imm
                    # Format A.1 - BRA/BCC instructions, always relative to PC
                    elif ifmt == "a1.1":
                        rdest = 15
                        # check if first operand has a space separated condition code
                        cond = cond_codes[condfield]
                        if is_register(opfields[0]):
                            rsrc2 = words[0]
                        else:
                            # Immediate is relative to PC
                            rsrc2 = 15
                            imm = words[0] - (nextmem+2)
                    # Format A.2, A.3 - JRCC and JSRCC instructions, dest always PC
                    elif ifmt == "a1.2":
                        rdest = 15
                        cond = cond_codes[condfield]
                        # check if first operand has a space separated condition code
                        if len(words)>1:
                            if is_register(opfields[0]):
                                rsrc2 = words[0]
                                imm = words[1]
                        elif is_register(opfields[0]):
                            imm = words[0]
                    # Format B, B1 and C - general logic and arithmetic
                    elif ifmt in ("b", "b1", "c"):
                        rdest = words[0];
                        rsrc1 = words[1];
                        if len(words) > 3:
                            rsrc2 = words[2]
                            imm = words[3]
                        elif is_register(opfields[2]):
                            rsrc2 = words[2]
                        else:
                            imm = words[2]
                        if ifmt in ("b", "b1"):
                            opcode = 0x20 + (op[inst]["opcode"] & 0x7)
                    # Format D - long JMP, CALL instructions, Format E, MOV Rd imm
                    elif ifmt == "d":
                        imm = words[0]
                    elif ifmt == "e":
                        rdest = words[0]
                        imm = words[1]
                    if ( debug ):
                        print (inst)
                        print ("opcode = %s" % op[inst]["opcode"])
                        print ("format = %s" % ifmt)
                        print ("rdest = %s" % rdest)
                        print ("rsrc1 = %s" % rsrc1)
                        print ("rsrc2 = %s" % rsrc2)
                        print ("cond = %d" % cond)
                        print ("imm   = %05x (%d)" % (imm,imm))

                    if ( not (instr_format[ifmt]["imm_lo"] <= imm <= instr_format[ifmt]["imm_hi"]) ):
                        errors.append("Error: immediate %d out of range (%d to %d) \n on line %s" % (imm, instr_format[ifmt]["imm_lo"], instr_format[ifmt]["imm_hi"], line.strip()))

                    # Break up immediate for recoding
                    imm50   = ((imm & 0b00000000000000111111)      ) 
                    imm76   = ((imm & 0b00000000000011000000) >> 6 ) if ifmt in ("b", "b1") else 0
                    imm96   = ((imm & 0b00000000001111000000) >> 6 ) if ifmt in ("e,d,a1.3,a1.2,a1.1,a".split(",")) else 0
                    imm1310 = ((imm & 0b00000011110000000000) >> 10) if ifmt in ("d","e") else 0
                    imm1514 = ((imm & 0b00001100000000000000) >> 14) if ifmt in ("d","e") else 0
                    imm1916 = ((imm & 0b11110000000000000000) >> 16) if ifmt in ("d") else 0

                    words=[ (op[inst]["opcode"]<<18)|
                            (imm76<<21) |
                            (imm1514<<18) |
                            ((rdest | cond | imm1916) <<14) |
                            ((rsrc1 | imm96) << 10)|
                            ((rsrc2 | imm1310) << 6) |
                            (imm50) ]
                    (wordmem[nextmem:nextmem+len(words)], nextmem,wcount )  = (words, nextmem+len(words),wcount+len(words))
            elif inst == "ORG":
                nextmem = eval(operands,globals(),symtab)
            elif inst in ("WORDALIGN", "WALIGN","ALIGN"):
                while ( nextmem % 4 ) :
                    nextmem += 1
            elif inst and (inst != "EQU") and iteration>0 :
                errors.append("Error: unrecognized instruction or macro %s in ...\n         %s" % (inst,line.strip()))
            if iteration > 0 and listingon==True:
                print("%08x   %-8s  %s"%(memptr,' '.join([("%06x" % i) for i in words]),line.rstrip()))

    print ("\nAssembled %d words of code with %d error%s and %d warning%s." % (wcount,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
    print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%08X (%08d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d|r\d\d|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))

    return wordmem


if __name__ == "__main__":
    """
    Command line option parsing.
    """
    filename = ""
    hexfile = ""
    output_filename = ""
    output_format = "hex"
    listingon = True
    start_adr = 0
    size = 0
    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:o:g:s:z:hn", ["filename=","output=","format=","start_adr=","size=","help","nolisting"])
    except getopt.GetoptError as  err:
        print(err)
        usage()

    if len(args)>=1:
        filename = args[0]
    if len(args)>1:
        output_filename = args[1]
        output_format = "hex"

    for opt, arg in opts:
        if opt in ( "-f", "--filename" ) :
            filename = arg
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
            size = 1024*1024 - start_adr
        print(header_text)
        wordmem = assemble(filename, listingon)[start_adr:start_adr+size]
        if len(errors)==0 and output_filename != "":
            if output_format == "hex":
                with open(output_filename,"w" ) as f:
                    f.write( '\n'.join([''.join("%08x " % d for d in wordmem[j:j+12]) for j in [i for i in range(0,len(wordmem),12)]]))
            else:
                with open(output_filename,"wb" ) as f:
                    # Write binary in little endian order
                    for w in wordmem:
                        bytes = bytearray()
                        bytes.append( w & 0xFF)
                        bytes.append( (w>>8) & 0xFF)
                        bytes.append( (w>>16) & 0xFF)
                        #bytes.append( (w>>24) & 0xFF)
                        f.write(bytes)
    else:
        usage()
    sys.exit( len(errors)>0)
