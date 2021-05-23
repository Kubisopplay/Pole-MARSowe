.data
	character: .asciiz '+'
.text
	
	la $a0, character
	li $v0, 1
	syscall
	