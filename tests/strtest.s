
        ;;
        ;; String test program
        ;;

#include "options.h"
#include "macros.h"
        ORG 0
        mov     r12,  stack-1

MACRO SPRINT ( _str_ )
        DATA
@s:     BSTRING _str_ + "\0"
        CODE
        mov     r1, @s
        jsr     sprint
ENDMACRO

ENDMACRO
MACRO SHOWSTRSTATS (_str_)
        mov     r1, m1
        jsr     sprint
        mov     r1, _str_
        jsr     sprint
        mov     r1, m2
        jsr     sprint
        mov     r1, _str_
        jsr     bstrlen
        jsr     printdec32
        PRINT_NL ()
ENDMACRO

MACRO STRCOMPARE (_str1_, _str2_)
        SPRINT  ( "Comparing: \012\015    s1: \0" )
        mov     r1, _str1_
        jsr     sprint
        SPRINT  ( "\015\012 vs s2: \0" )
        mov     r1,  _str2_
        jsr     sprint
        PRINT_NL ()
        mov     r1, _str1_
        mov     r2, _str2_
        jsr     bstrcmp
        cmp     r1, 0
        bra lt  @less
        bra gt  @more
        SPRINT ("Result: s1 equal to s2 \015\012\0")
        bra     @exit
@less:
        SPRINT ("Result: s1 less than s2\015\012\0")
        bra     @exit
@more:
        SPRINT ("Result: s1 greater than s2\015\012\0")
        bra     @exit
@exit:
        PRINT_NL ()
ENDMACRO

MACRO STRCOPYANDCOMPARE ( _str1_ , _str2_ )
        SPRINT  ("Copying string \'\0")
        mov     r1, _str1_
        jsr     sprint
        SPRINT  ("\'\012\015\0")
        mov     r1, _str1_
        mov     r2, _str2_
        jsr     bstrcpy
        SPRINT  ("Comparing strings ...\0")
        mov     r2, _str2_      ; get addr of copied string
        mov     r1, _str1_      ; get addr of original string
        jsr     bstrcmp
        cmp     r1, 0
        bra nz  @fail
        SPRINT  ("PASS.\012\015\0")
        bra     @exit
@fail:
        SPRINT ("FAIL.\012\015\0")
@exit:
ENDMACRO

        SHOWSTRSTATS( s1)
        SHOWSTRSTATS( s2)
        SHOWSTRSTATS( s3)
        SHOWSTRSTATS( s4)

        STRCOMPARE ( s1, s2 )
        STRCOMPARE ( s1, s1 )
        STRCOMPARE ( s1, s3 )
        STRCOMPARE ( s2, s3 )
        STRCOMPARE ( s4, s2 )
        STRCOMPARE ( s3, s2 )

        STRCOPYANDCOMPARE( s1, dest)
        STRCOPYANDCOMPARE( s2, dest)
        STRCOPYANDCOMPARE( s3, dest)
        STRCOPYANDCOMPARE( s4, dest)

        HALT    ()

        #include "include/intmath.s"
        #include "include/stdio.s"
        #include "include/stdlib.s"
        #include "include/bstring.s"

        DATA
        ; DATA MEM defines after any local memory for include files

s1:     BSTRING  "This is a string\0"
s2:     BSTRING  "This is a longer string\0"
s3:     BSTRING  "This is a very long string\0"
s4:     BSTRING  "This is a very, very long string!\0"

m1:     BSTRING  "String \'\0"
m2:     BSTRING  "\' has length \0"

        ; Make some space to trial string copying
dest:   DATA 128


        EQU     stack, 8191   ; Stack at top of memory
