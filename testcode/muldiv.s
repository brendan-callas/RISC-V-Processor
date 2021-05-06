mulsdiv_test.s:
.align 4
.section .text
.globl _start



_start:
      #lw x1, sixnine
      #lw x2, sixnine
      #mul x3, x1, x2
	  
      #lw x1, neg_one
      #lw x2, two
      #mulh x4, x1, x2

	  #lw x1, neg_one
	  #lw x2, neg_two
	  #mul x4, x1, x2
      #mulh x5, x1, x2
      #mulhsu x6, x1, x2
      #mulhsu x7, x2, x1

      #lw x1, one
      #lw x2, two
      #div x8, x1, x2
      #rem x9, x1, x2
	  #div x10, x2, x1
	  #rem x11, x2, x1

      #lw x1, two
      #lw x2, zero
      #divu x10, x1, x2
      #remu x11, x1, x2

	  lw x1, num3
	  lw x2, sixnine
	  mul x3, x2, x2
	  mulh x4, x1, x1
      mulhu x5, x1, x1
      mulhsu x6, x1, x1
      #mulhsu x7, x1, x1
	  
done:
      beq x0, x0, done

.section .rodata

big:	  		  .word	0x00100000
sixnine:		  .word 0x00000045
big_neg:          .word 0x80000000
five:             .word 0x00000005
one:     	      .word 0x00000001
seven:            .word 0x00000007
two:              .word 0x00000002
zero:		      .word 0x00000000
num1:             .word 0x00000423
num2:             .word 0x0000514A
num3:			  .word 0x0150451E
neg_one:          .word 0xFFFFFFFF
neg_two:		  .word 0xFFFFFFFE
