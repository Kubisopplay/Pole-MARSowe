.data
	Array: .space 1024
	ArraySize: .word 256
	
	Msg: .asciiz "String length is: "
	InputPrompt: .asciiz "Pls input:\n"
.text       
			#string reading
	la $a1, 1024	# syscall 8 read_string
	la $a0, Array
	li $v0, 8	# $a1 -> maximum number of characters to read
	syscall		#now $a0 -> address of input buffer
	
	la $t1, Array	
	addi $t1,$t1,-1		
	
	RunLoop:		
	lb $t4, ($t1)
	addi $t1, $t1, 1	
	beq $t4, ' ', RunLoop	
	beq $t4, '\n', EndLoop
	
	
	
	#move $a0, $t4
	#li $v0, 11
	syscall
	
	j RunLoop
	
	EndLoop:
	li $v0, 10
	syscall
	
	
	
	
	
	
