.data
	a1: .word 5
	b1: .word 10
	br: .asciiz "\n"
.text
	lw $t0, a1
	lw $t1, b1
	mul $s0, $t0, $t1
	div $t1, $t2
	
	li $v0, 1
	add $a0, $zero, $s0
	syscall
	
	#li $v0, 4
	#la $a0, br
	#syscall
	
	li $v0, 1
	add $a0, $zero, $hi
	syscall
	