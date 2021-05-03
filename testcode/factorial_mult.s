factorial.s:
 .align 4
 .section .text
 .globl factorial
 factorial:
		  lw x0, test #remove before submitting

		 xor x0, x0, x0 #zero all regs
		 xor x1, x1, x1
		 xor x2, x2, x2
		 xor x3, x3, x3
		 xor x5, x5, x5
		 xor x6, x6, x6
		 xor x7, x7, x7

#		 addi x0, x0, 2 # x0 = 2 to determine if we're done multiplying
#
#		 add x6, x0, x6 # x6 = input
#		 addi x5, x6, -1 # x5 = x6 - 1
#
# fact_2:
#		blt x5, x0, ret # are we done? (x5 == 2)
#		beq x7, x7, mult_main # jump to multiplication step
#
# mult_main:
#		xor t2, t2, t2 # clear regs for new mult
#		xor t3, t3, t3
#		add t2, t2, t6 # init t2 for mult step
#		addi t3, t5, -1 # t3 = t5 - 1 to init counter
#		beq x7, x7, mult_loop
# 
# mult_loop:
#		beq t1, t3, mult_done # if we're done multiplying (t3 == 0)
#		add t6, t6, t2		  # t6 = t2 + t6 (add as part of mult)
#		addi t3, t3, -1		  # decrement counter reg
#		beq x7, x7, mult_loop # always loop back
#
# mult_done:
#		addi t5, t5, -1 # decrement t5 for number of adds
#		beq x7, x7, fact_2 # return to fact_2


	lw	x6, test

mult_main:
	xor x1, x1, x1
	xor x2, x2, x2
	add x5, x5, x6 #init prod
	add x2, x2, x6 #init counter
	addi x2, x2, -1
	beq x7, x7, mult_loop

mult_loop:
	beq x1, x2, ret #if x2 == 0 and we're done
	mul x5, x5, x2 #multiply cur prod by cur counter
	addi x2, x2, -1 #decrement counter
	beq x7, x7, mult_loop

ret:
		 xor x3, x3, x3
		 add x3, x3, x5 # return value goes in x3

done:
	beq x0, x0, done

 .section .rodata
 # if you need any constants
 test:    .word 0x0000000c
