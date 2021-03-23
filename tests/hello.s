        ;; Hello World
        ;;
        ;; Simple test of string handling
#include "options.h"
#include "macros.h"

        ORG     0x0000
        movi    r12, stack_top

        movi    r1, msg
        jsr     sprint

        HALT    ()

#include "include/stdio.s"

        # data Section
        DATA
msg:    BSTRING "Hello, World!\r\0"

        EQU     stack_top, 0x01FF
