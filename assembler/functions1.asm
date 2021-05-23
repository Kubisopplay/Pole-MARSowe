.data
	message: .asciiz "Hello Assembler \n My name is Jakub \n"
.text
	main:
		jal displayMessage
		
	#DONE 
	li $v0, 10
	syscall
	
	displayMessage:
		li $v0, 4
		la $a0, message
		syscall
		
		jr $ra