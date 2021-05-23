.data 
	
.text
	addi $t0, $zero, 200000
	addi $t1, $zero, 100000
	
	mult $t0, $t1
	
	#mflo $s0
	mfhi $s0 
	
	#display product to the screen
	
	li $v0, 1
	add $a0, $zero, $s0
	syscall
	