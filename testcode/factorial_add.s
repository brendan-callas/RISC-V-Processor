factorial.s:
 .align 4
 .section .text
 .globl factorial
 factorial:
		 lw x1, test 

		 xor x2, x2, x2 #zero all regs
		 xor x3, x3, x3
		 xor x4, x4, x4
		 xor x5, x5, x5
		 xor x6, x6, x6
		 xor x7, x7, x7
		 xor x8, x8, x8

		 addi x2, x2, 2 # x2 = 2 to determine if we're done multiplying

		 add x8, x1, x8 # x8 = input
		 addi x7, x8, -1 # x7 = x8 - 1

 fact_2:
		blt x7, x2, ret # are we done? (x7 == 2)
		beq x0, x0, mult_main # jump to multiplication step

 mult_main:
		xor x4, x4, x4 # clear regs for new mult
		xor x5, x5, x5
		add x4, x4, x8 # init x4 for mult step
		addi x5, x7, -1 # x5 = x7 - 1 to init counter
		beq x0, x0, mult_loop
 
 mult_loop:
		beq x3, x5, mult_done # if we're done multiplying (x5 == 0)
		add x8, x8, x4		  # x8 = x4 + x8 (add as part of mult)
		addi x5, x5, -1		  # decrement counter reg
		beq x0, x0, mult_loop # always loop back

 mult_done:
		addi x7, x7, -1 # decrement t5 for number of adds
		beq x0, x0, fact_2 # return to fact_2

 ret:
		 xor x1, x1, x1
		 add x1, x1, x8 # return value goes in a0

done:
	beq x0, x0, done

 .section .rodata
 # if you need any constants
 test:    .word 0x0000000c
