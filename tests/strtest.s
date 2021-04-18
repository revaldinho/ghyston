
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

MACRO STRCOPY ( _str1_ , _str2_ )
        SPRINT  ("Copying string \'\0")
        mov     r1, _str2_
        jsr     sprint
        SPRINT  ("\'\012\015\0")
        mov     r1, _str1_
        mov     r2, _str2_
        jsr     bstrcpy
ENDMACRO

MACRO STRCAT ( _str1_ , _str2_ )
        SPRINT  ("Concatenating string \'\0")
        mov     r1, _str2_
        jsr     sprint
        SPRINT  ("\'\012\015onto end of string \'\0")
        mov     r1, _str1_
        jsr     sprint
        SPRINT  ("\'\012\015\0")
        mov     r1, _str1_
        mov     r2, _str2_
        jsr     bstrcat
        SPRINT  ("New string \'\0")
        mov     r1, _str1_
        jsr     sprint
        SPRINT  ("\'\012\015\0")
ENDMACRO

MACRO GETBYTE ( _str1_, _bnum_ )
        SPRINT  ("The \0")
        mov     r1, _bnum_
        jsr     printdec32
        SPRINT  ("th byte of \'\0")
        mov     r1, _str1_
        jsr     sprint
        SPRINT  ("\' is "\0)
        mov     r1, _str1_
        mov     r2, _bnum_
        jsr     getbstrbyte
        PUSH    (r1)

        cmp     r1, 0
        bra z   @l1
        jsr     oswrch
        SPRINT  ("  [\0")
        POP     (r1)
        jsr     printdec32
        SPRINT  ( "]\0")
        PRINT_NL ()
        bra     @l2
@l1:
        SPRINT  ("String length exceeded\012\015\0")
@l2:
ENDMACRO

MACRO PUTBYTE ( _str1_, _bnum_ , _char_)
        SPRINT  ("Replacing the \0")
        mov     r1, _bnum_
        jsr     printdec32
        SPRINT  ("th byte of \'\0")
        mov     r1, _str1_
        jsr     sprint
        SPRINT  ("\' with "\0)
        mov     r1, _char_
        jsr     oswrch
        PRINT_NL ()
        mov     r1, _str1_
        mov     r2, _bnum_
        mov     r3, _char_
        jsr     putbstrbyte
        mov     r1, _str1_
        jsr     sprint
        PRINT_NL ()
        bra     @l2
@l1:
        SPRINT  ("String length exceeded\012\015\0")
@l2:
ENDMACRO



        SPRINT("\012\015STRLEN Test\012\015\0")

        SHOWSTRSTATS( s1)
        SHOWSTRSTATS( s2)
        SHOWSTRSTATS( s3)
        SHOWSTRSTATS( s4)

        SPRINT("\012\015STRCMP Test\012\015\0")

        STRCOMPARE ( s1, s2 )
        STRCOMPARE ( s1, s1 )
        STRCOMPARE ( s1, s3 )
        STRCOMPARE ( s2, s3 )
        STRCOMPARE ( s4, s2 )
        STRCOMPARE ( s3, s2 )

        SPRINT("\012\015STRCPY Test\012\015\0")

        STRCOPY(dest, s1)
        STRCOMPARE(dest, s1)
        STRCOPY(dest, s3)
        STRCOMPARE(dest, s3)
        STRCOPY(dest, s2)
        STRCOMPARE(dest, s2)
        STRCOPY(dest, s4)
        STRCOMPARE(dest, s4)
        PRINT_NL()

        SPRINT("\012\015STRCAT Test\012\015\0")

        STRCOPY( dest, s1)
        STRCAT( dest , s1)
        STRCOPY( dest, s2)
        STRCAT( dest , s1)
        STRCOPY( dest, s3)
        STRCAT( dest , s2)

        SPRINT("\012\015GETBYTE Test\012\015\0")

        GETBYTE( s1, 0)
        GETBYTE( s1, 1)
        GETBYTE( s1, 2)
        GETBYTE( s1, 3)
        GETBYTE( s1, 4)
        GETBYTE( s1, 18)
        GETBYTE( s4, 19)
        GETBYTE( s4, 20)

        SPRINT("\012\015PUTBYTE Test\012\015\0")

        PUTBYTE( s1, 0, 64)
        PUTBYTE( s1, 1, 65)
        PUTBYTE( s1, 2, 66)
        PUTBYTE( s1, 3, 67)
        PUTBYTE( s1, 4, 68)

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
