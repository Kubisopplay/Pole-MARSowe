.data
	a: .word 5
	
.text
	lw $t0, a
	li $v0, 1
	add $a0, $zero, $t0
	syscall
