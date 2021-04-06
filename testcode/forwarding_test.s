#  mp4-cp2.s version 1.3
.align 4
.section .text
.globl _start
_start:

add x1, x0, 1


forwarding_tests:
    # Forwarding x0 test
    add x3, x3, 1
    add x0, x1, 0
    add x2, x0, 0

    beq x2, x3, oof
	nop
	nop
	nop
	nop
	nop

    # Forwarding sr2 imm test
    add x2, x1, 0
    add x3, x1, 2                      # 2 immediate makes sr2 bits point to x2
    add x4, x0, 3

    bne x3, x4, oof                    # Also, test branching on 2 forwarded values :)
	nop
	nop
	nop
	nop
	nop

    # MEM -> EX forwarding with stall
    lw x1, NOPE
    lw x1, A
    add x5, x1, x0                     # Necessary forwarding stall

    bne x5, x1, oof
	nop
	nop
	nop
	nop
	nop

    # WB -> MEM forwarding test
    add x3, x1, 1 #2
    la x8, TEST
    sw  x3, 0(x8)
    lw  x4, TEST

    bne x4, x3, oof
	nop
	nop
	nop
	nop
	nop


    # Half word forwarding test
    lh  x2, FULL
    add x3, x0, -1

    bne x3, x2, oof
	nop
	nop
	nop
	nop
	nop

    # Cache miss control test
    add x4, x0, 3
    lw  x2, B                          # Cache miss
    add x3, x2, 1                      # Try to forward from cache miss load

    bne x4, x3, oof
	nop
	nop
	nop
	nop
	nop

    # Forwarding contention test
    add x2, x0, 1
    add x2, x0, 2
    add x3, x2, 1

    beq x3, x2, oof
	nop
	nop
	nop
	nop
	nop

    lw x7, GOOD

halt:
    beq x0, x0, halt
    nop
	nop
	nop
	nop
	nop

oof:
    lw x7, BAD
    lw x2, PAY_RESPECTS
    beq x0, x0, halt
	nop
	nop
	nop
	nop
	nop



.section .rodata
.balign 256
DataSeg:
    nop
    nop
    nop
    nop
    nop
    nop
BAD:            .word 0x00BADBAD
PAY_RESPECTS:   .word 0xFFFFFFFF
# cache line boundary - this cache line should never be loaded

A:      .word 0x00000001
GOOD:   .word 0x600D600D
NOPE:   .word 0x00BADBAD
TEST:   .word 0x00000000
FULL:   .word 0xFFFFFFFF
        nop
        nop
        nop
# cache line boundary

B:      .word 0x00000002
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

C:      .word 0x00000003
        nop
        nop
        nop
        nop
        nop
        nop
        nop
# cache line boundary

D:      .word 0x00000004
        nop
        nop
        nop
        nop
        nop
        nop
        nop
