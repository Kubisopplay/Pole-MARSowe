.data
	a1: .word -5
	b1: .word 10
 	PI: .float 3.14
 	br: .asciiz "\n"
 	myDouble: .double 2.202
 	zeroDouble: .double 0.0
 .text
	lw $t1, a1
	lw $t2, b1
	li $v0, 1
	addu $a0, $t1, $t2
	syscall
	
	li $v0, 4
	la $a0, br
	syscall
	
	li $v0 2
	lwc1 $f12, PI
	syscall 
	
	li $v0, 4
	la $a0, br
	syscall
	
	ldc1 $f2, myDouble
	ldc1 $f0, zeroDouble
	
	li $v0, 3
	add.d $f12, $f0, $f2
	syscall
	
	