        ;; Assembler options files

        ;; define this to optimize for hardware multiplier but limited to 18x18 operation
        ;; #define MUL18X18 1
        ;; Need to define one and only one of the following defines for the division
        ;; #define NOUNROLL_UDIV
        ;; #define UNROLL_UDIV2 1
#define UNROLL_UDIV4 1
        ;; #define UNROLL_UDIV8 1
        ;;  Define this if full 0-31 place shifts are implemented
        ;; #define SHIFT_32
        ;; Define this if native DJNZ is implemented
#define DJNZ_INSTR 1
        ;; Define this if NEG instr is implemented
#define NEG_INSTR 1
#define ZLOOP_INSTR 1
