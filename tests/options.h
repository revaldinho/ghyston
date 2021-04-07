        ;; Assembler options files
        ;; define this to optimize for hardware multiplier but limited to 18x18 operation
        ;; #define MUL18X18 1

        ;; define this to use standard library intmath.s rather than dedicated routines for Pi
        ;;#define USE_STD_LIB 0
        ;; Need to define one and only one of the following defines for the division in PI routine
#define NOUNROLL_UDIV 1
        ;; #define UNROLL_UDIV2 1
        ;; #define UNROLL_UDIV4 1
        ;;  Define this if full 0-31 place shifts are implemented
        ;; #define SHIFT_32
        ;; Define this if native DJNZ and DJZ are implemented
        ;; #define DJNZ_INSTR 1
        ;; Define this if NEG instr is implemented
        ;; #define NEG_INSTR 1
        ;; #define ZLOOP_INSTR 1
#define PRED_INSTR 1
