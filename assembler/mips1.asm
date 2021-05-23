.data
	myMessage: .asciiz "Hello World \n"
	myChar: .byte 'm'
.text
	li $v0, 4
	la $a0, myMessage
	syscall
	la $a0, myChar
	syscall
	li $v0, 10
	
