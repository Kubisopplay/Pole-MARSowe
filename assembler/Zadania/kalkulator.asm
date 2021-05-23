.macro print_string(%value)
	li $v0, 4
	la $a0, %value
	syscall 
.end_macro 

#print %question and save answer to %register
.macro askAndSave(%question, %register)
	li $v0, 4
	la $a0, %question
	syscall 
	li $v0, 5
	syscall
	move %register, $v0
.end_macro 


.data
	askAboutEquation: .asciiz  "\nSelect operation:\n[0]-(a+b)\n[1]-(a-b)\n[2]-(a*b)\n[3]-(a/b)\n"
	askAboutA: .asciiz "Give number a:\n"
	askAboutB: .asciiz "Give number b:\n"
	askSave: .asciiz "\n\nSave result? \n[0]-NO \n[1]-YES\n"
	askExit: .asciiz "\nWant to exit? \n[0]-NO \n[1]-YES\n"
	
	decision: .space 4
	a: .space 4
	b: .space 4
	
	res: .asciiz "\nResult: "
.text
	
main:
	beq $t1, 0, nosaves
	
	# $t0 - type of equations
	# $t1 - want to save
	# $t2 - want to exit
	
	# $a1 - number a
	# $a2 - nubmer b
	
	# $v1 - results of operations
	
	#ask and save type of equation, a and b
	nosaves:
	askAndSave(askAboutEquation, $t0)
	askAndSave(askAboutA, $a1)
	askAndSave(askAboutB, $a2)
	j operation_if
	
	#ask and save type of equation and a
	saves:
	move $a1, $v1
	askAndSave(askAboutEquation, $t0)
	askAndSave(askAboutB, $a2)
	j operation_if
	
	#do the operation
	operation_if:
	beq $t0, 0, addition
	beq $t0, 1, subtraction
	beq $t0, 2, multiplication
	beq $t0, 3, division	
	exit:

	#print result
	print_string(res)
	li $v0, 1
	move $a0, $v1
	syscall
	
	#ask about save
	move $t1, $zero #just for sure
	askAndSave(askSave, $t1)
	beq $t1, 1, saves
	
	#ask about exit		
	askAndSave(askExit, $t2)
	beq $t2, 0, main
		
	#END
	li $v0, 10
	syscall
	

addition:
	add $v1, $a1, $a2
	j exit
	
subtraction:
	sub $v1, $a1, $a2
	j exit

multiplication:
	mul $v1, $a1, $a2
	j exit

division:
	div $v1, $a1, $a2
	j exit
	
	


