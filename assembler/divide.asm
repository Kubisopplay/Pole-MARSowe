.data

.text
	addi $t0, $zero, 100 # $t0 = 0 + 100
	addi $t1, $zero, 20  # $t1 = 0 + 20
	
	div $s0, $t0, $t1    # $s0 = 100/20
	 
	#print
	li $v0, 1
	add $a0, $zero, $s0  # $a0 = address($s0)
	syscall
	