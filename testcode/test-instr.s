#  test-instr.s         code that we wrote ourself to test the specific instructions
.align 4
.section .text
.globl _start
_start:    # test lui
    /*lui x10, %hi(NEGTWO)
    addi x10,x10, %lo(NEGTWO)
    lw  x11, (x10)
    lui x12, %hi(GOOD)
    lw  x12, %lo(GOOD)(x12)
    lui x13, %hi(BADD) 
    lw  x13, %lo(BADD)(x13)
    lui x14, %hi(BYTES)
    lw  x14, %lo(BYTES)(x14)
    and x10, x10, x0
    and x11, x11, x0
    and x12, x12, x0
    and x13, x13, x0*/

	lw x12, BADD

    lui x12, %hi(BADD)
    lw  x12, %lo(BADD)(x12)

	


    nop
    nop

test_jal:
    jal x5, test_jal_2
    nop
    nop
    nop
    nop
    nop
test_jal_3:
    lui x11, %hi(TWO)
    lw  x11, %lo(TWO)(x11)

    jal x0, _end
    nop
    nop
    nop
    nop
    nop

.section .rodata
.balign 256
ONE:    .word 0x00000001
TWO:    .word 0x00000002
NEGTWO: .word 0xFFFFFFFE
TEMP1:  .word 0x00000001
GOOD:   .word 0x600D600D
BADD:   .word 0xBADDBADD
BYTES:  .word 0x04030201
HALF:   .word 0x0020FFFF

.section .text
.align 4
test_jal_2:
    lui x10, %hi(ONE)
    lw  x10, %lo(ONE)(x10)
    jalr x0, (x5)
#    jal x0, test_jal_3
    nop
    nop
    nop
    nop
    nop

_end:
    lui x12, %hi(GOOD)
    lw  x12, %lo(GOOD)(x12)
    and x13, x13, x0
    nop
    nop
    nop
    nop
    nop
