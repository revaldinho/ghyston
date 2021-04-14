        ;;
        ;; Sorting test program
        ;;

#include "options.h"
#include "macros.h"
        EQU     MAX,  128            # size of array
        EQU     HEAD, 10
        EQU     TAIL, 10

        ORG 0

        ;; generate an array of random numbers

        mov     r5, MAX
        mov     r6, randarr - 1
        mov     r12, stack-1
l0:
        mov     r1, 1000
        jsr     rand            ; generate random number <1000
        add     r0, r5, r6
        sto     r1, r0
        DJNZ    (r5, l0)

        mov     r1, randarr
        mov     r2, array1
        mov     r3, MAX
        jsr     memcpy

        mov     r1, msg0
        mov     r2, randarr
        mov     r3, MAX
        jsr     arrsum

        mov     r1, array1
        mov     r2, MAX
        jsr     bsort

        mov     r1, msg2
        mov     r2, array1
        mov     r3, MAX
        jsr     arrsum

        mov     r1, randarr
        mov     r2, array2
        mov     r3, MAX
        jsr     memcpy

        mov     r1, array2
        mov     r2, MAX
        jsr     ssort

        mov     r1, msg2
        mov     r2, array2
        mov     r3, MAX
        jsr     arrsum


        ;;  compare the results of the bubble and shell sorts
        mov     r1, array1
        mov     r2, array2
        mov     r3, MAX
        jsr     memcmp
        mov     r1, msg10
        jsr     sprint

        cmp     r1, 0
        bra nz  fail
        mov     r1, msg8
        bra     end
fail:   mov     r1, msg9
end:    jsr     sprint
        mov     r1, msg10
        jsr     sprint

        HALT    ()


        ;; -----------------------------------------------------
        ;; Shell Sort
        ;;
        ;; Use power of 2 for quick mul/division
        ;;
        ;; Entry
        ;; - r1 pointer to array data
        ;; - r2 number of entries
        ;; -----------------------------------------------------
ssort:
        PUSH    (r14)
        mov     r8, 0           ; swaps counter
        mov     r9, r1          ; r9 = array ptr
        mov     r10, r2         ; r10 = N

        mov     r1, msg7
        jsr     sprint

        mov     r11, 1          ; h = 1
ssort0:
        cmp     r11, r10
        bra ge  ssort1
        asl     r11, r11, 1     ; h = h*2 + 1
        add     r11, r11, 1
        bra     ssort0

ssort1:
        cmp     r11, 1
        bra  le ssort5
        lsr     r11, r11, 1     ; h = h//2
        mov     r3, r11         ; i = r3 = r11
ssort2:
        cmp     r3, r10
        bra ge  ssort1

        add     r0, r3, r9      ; ptr = array + i
        ld      r4, r0          ; v = *(array + i)
        mov     r7, r3          ; j = i

#ifdef ZLOOP_INSTR
        zloop   ssort4
#endif
ssort3:
        sub     r0, r7, r11     ; j-h
        add     r0, r0, r9      ; (arr + j-h)
        ld      r5, r0          ; *(arr + j - h)
        cmp     r5, r4
        bra le  ssort4
        ;; arr[j] = arr[j-h]
        add     r8, r8, 1       ; swaps++
        add     r1, r0, r11     ; arr + j (ie arr+j-h+h)
        ld      r5, r0
        sto     r5, r1
        sub     r7, r7,r11      ; j = j-h
        cmp     r7, r11
#ifdef ZLOOP_INSTR
        bra lt  ssort4          ; breakout if less than
#else
        bra ge  ssort3          ; loop again is greater or equal
#endif
ssort4:
        add     r8, r8, 1       ; swaps ++
        add     r0, r7, r9      ; arr + j
        sto     r4, r0          ; arr[j] = v

        add     r3, r3, 1       ; i++
        bra     ssort2
ssort5:
        ;;  Print the stats before leaving
        mov     r1, msg5
        jsr     sprint
        mov     r1, r8
        jsr     printdec32
        PRINT_NL ()
        POP     (r14)
        ret

        ;; --------------------------------------------------------
        ;; Bubble Sort
        ;;
        ;; Entry
        ;; - r1 pointer to array data
        ;; - r2 number of entries
        ;; --------------------------------------------------------
bsort:
        PUSH    (r14)
        mov     r10,r1          ; r10 = array pointer
        mov     r9, r2          ; r9 = number of entries
        mov     r1, msg6
        jsr     sprint

        mov     r7, 0           ; total passes through array
        mov     r6, 0           ; total swaps
bsort4:
        mov     r1, 0           ; swaps = 0
        sub     r2, r9, 1       ; index start at Max-1 (to compare with i-1)
#ifdef ZLOOP_INSTR
        zloop   bsort3
#endif
bsort0:
        add     r0, r2,r10
        ld      r4, r0          ; r4 = MEM[i]
        sub     r5, r0, 1
        ld      r3, r5          ; r3 = MEM[i-1]
        cmp     r3, r4
        bra le  bsort1          ; if r3 > r4 then swap
        sto     r3, r0
        sto     r4, r5
        add     r1, r1, 1       ; .. and increment swap counter
bsort1:
#ifdef ZLOOP_INSTR
        DJZ     (r2, bsort3)    ; break out when r2 reaches 0
#else
        DJNZ    (r2, bsort0)    ; loop again if r2 not 0
#endif
bsort3:
        add     r6, r6, r1      ; increment total swap counter
        add     r7, r7, 1       ; increment pass counter
        cmp     r1, 0           ; check swap counter
        bra nz  bsort4          ; and repeat if not zero

        ;;  Print the stats before leaving
        mov     r1, msg3
        jsr     sprint
        mov     r1, r7
        jsr     printdec32
        PRINT_NL ()
        mov     r1, msg5
        jsr     sprint
        mov     r1, r6
        jsr     printdec32
        PRINT_NL ()
        POP     (r14)
        ret     r14


        ;; Array Summary - print the head and tail of the array
        ;; - r1 message pointer
        ;; - r2 start of array
        ;; - r3 number of words


arrsum: PUSH    (r14)
        PUSH    (r8)
        PUSH    (r7)
        PUSH    (r6)
        PUSH    (r5)

        mov     r7, r2
        mov     r8, r3

        jsr     sprint
        mov     r5, 0
        mov     r6, r7


l1:     add     r0, r5, r6
        ld      r1, r0
        jsr     printdec32
        mov      r1, ord(' ')
        jsr     oswrch
        add     r5, r5, 1
        cmp     r5, TAIL
        bra nz  l1

        mov     r1, msg1
        jsr     sprint
        sub     r5, r8, (TAIL+1)
        mov     r6, r7

l2:     add     r0, r5, r6
        ld      r1, r0
        jsr     printdec32
        mov      r1, ord(' ')
        jsr     oswrch
        add     r5, r5, 1
        cmp     r5, r8
        bra nz  l2

        PRINT_NL ()

        POP     (r5)
        POP     (r6)
        POP     (r7)
        POP     (r8)
        POP     (r14)
        ret     r14

        #include "include/intmath.s"
        #include "include/stdio.s"
        #include "include/stdlib.s"
        DATA
        ; DATA MEM defines after any local memory for include files
msg0:   BSTRING "Unsorted array: \0"
msg1:   BSTRING "... \0"
msg2:   BSTRING "Sorted array  : \0"
msg3:   BSTRING "Passes through array: \0"
msg5:   BSTRING "Total swaps:          \0"
msg6:   BSTRING "**  B U B B L E   S O R T  **\012\015\0"
msg7:   BSTRING "**  S H E L L  S O R T  **\012\015\0"
msg8:   BSTRING "PASS - result arrays match\012\015\0"
msg9:   BSTRING "FAIL - mismatch in result arrays\012\015\0"
msg10:  BSTRING "----------------------------------- \012\015\0"

randarr:
        DATA MAX               ; reserve space for the array
array1:
        DATA MAX               ; reserve space for the array
array2:
        DATA MAX               ; reserve space for the array

        EQU     stack, 8191   ; Stack at top of memory
