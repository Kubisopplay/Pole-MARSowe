.data
	br: .asciiz "\n"
.text
	addi $t0, $zero, 30
	addi $t1, $zero, 5
	
	div $s0, $t0, $t1
	div $t0, $t1
	
	li $v0, 1
	add $a0, $zero, $s0
	syscall
	
	li $v0, 4
	la $a0, br
	syscall
	
	mflo $s0
	li $v0, 1
	add $a0, $zero, $s0
	syscall