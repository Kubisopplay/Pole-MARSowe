.macro print_string(%value)
	li $v0, 4
	la $a0, %value
	syscall 
.end_macro 

.macro print_registers()

	print_string(memoryText)	
	mov.s $f12, $f10 #move memory value to $f12
	li $v0, 2	
	syscall
	
	print_string(aText)
	mov.s $f12, $f1
	li $v0, 2	
	syscall
	
	print_string(bText)
	mov.s $f12, $f2
	li $v0, 2	
	syscall
	
.end_macro 

.macro print_memory()
	print_string(memoryText)
	
	mov.s $f30, $f12 #move result to $f30(temporary register)
	mov.s $f12, $f10 #move memory value to $f12
	li $v0, 2	
	syscall
	mov.s $f12, $f30 #back result to $f12
.end_macro 

#print %question and save answer(integer) to %register
.macro askAndSaveInt(%question, %register)
	li $v0, 4
	la $a0, %question
	syscall 
	li $v0, 5	#user value is now in $v0
	syscall
	move %register, $v0
.end_macro 

#print %question and save answer(float) to %register
.macro askAndSaveFloat(%question, %register)
	li $v0, 4
	la $a0, %question
	syscall 
	li $v0, 6	#user value is now in $f0
	syscall
	mov.s %register, $f0
.end_macro 

	#REGISTER DESCRIPTION
	#
	# $t0 - type of equations
	# $t1 - want to save
	# $t2 - want to exit
	#
	# $t3 / $t4 - help registers in factorial/power function
	#
	# $t6 - 0 - read a / !0 - skip reading a
	# $t7 - 0 - read b / !0 - skip reading b
	#
	#
	# $f1 - number a
	# $f2 - number b
	# $f3 - temporary (factorial and power)
	# $f5 - result of operation
	#
	# $f10 - Memory value
	# f12 - float to be printed [syscall prints]



.data
	askAboutEquation: .asciiz  "\nSelect operation:\n[0]-(a+b)\n[1]-(a-b)\n[2]-(a*b)\n[3]-(a/b)\n[4]-(1/a)\n[5]-(|a|)\n[6]-(a!)\n[7]-(a^b)\n[8]-(Read memory to a)\n[9]-(Read memory to b)\n[10]-(exit)\n"
	askAboutA: .asciiz "Give number a:\n"
	askAboutB: .asciiz "Give number b:\n"
	askSave: .asciiz "\nWhat to do with result? \n[0]- SKIP \n[1]-SAVE AS a\n[2]-ADD TO MEMORY\n[3]-SUBTRACT FROM MEMORY\n[4]-CLEAR MEMORY\n"
	
	memoryText: .asciiz "\nValue in memory: "
	aText: .asciiz "\na="
	bText: .asciiz "\nb="
	
	float_one: .float 1.0
	float_zero: .float 0.0
	
	res: .asciiz "\nResult: "
	err: .asciiz "\nError in operation"
.text
	
main:
	lwc1 $f1, float_zero	#a: $f1 = 0  
	lwc1 $f2, float_zero	#b: $f2 = 0
	lwc1 $f10, float_zero	#memory: $f10 = 0
	move $t6, $zero		#$t6 = 0 => read a
	move $t7, $zero		#$t7 = 0 => read b
	lwc1 $f1, float_zero	#a: $f1 = 0  
	lwc1 $f2, float_zero	#b: $f2 = 0
	
	menu:
	lwc1 $f5, float_zero
	print_registers()
	askAndSaveInt(askAboutEquation, $t0)
	beq $t0, 8, loadMemoryAsA	# a = memory value and skip reading a
	beq $t0, 9, loadMemoryAsB	# b = memory value and skip reading b
	beq $t0, 10, exit		
	
	beq $t6, 0, read_a
	
	check_one_argument_ops:		#skip reading b
	beq $t0, 4, inversion
	beq $t0, 5, absolute
	beq $t0, 6, factorial
	
	beq $t7, 0, read_b
	j end_read
	
	read_a:
		askAndSaveFloat(askAboutA, $f1)
		beq $t7, 1, end_read
		j check_one_argument_ops
		
	read_b:
		askAndSaveFloat(askAboutB, $f2)
		j end_read
	
	end_read:
	
	#reset saving decisions
	move $t6, $zero
	move $t7, $zero
	
	#operations that need a and b
	operation_if:
	beq $t0, 0, addition
	beq $t0, 1, subtraction
	beq $t0, 2, multiplication
	beq $t0, 3, division
	beq $t0, 7, power	
	
	#print result
	show_result:
	lwc1 $f1, float_zero	#a: $f1 = 0  
	lwc1 $f2, float_zero	#b: $f2 = 0
	print_string(res)
	mov.s $f12, $f5		#$f12 = $f5 (result of operations)
	li $v0, 2		#syscall 2 prints float from $f12
	syscall
	
	print_memory()
	askAndSaveInt(askSave, $t1)
	beq $t1, 0, menu
	beq $t1, 1, save_result_as_a
	beq $t1, 2, addToMemory
	beq $t1, 3, subtractFromMemory
	beq $t1, 4, clearMemory
	j show_result
	
	save_result_as_a:
		add $t6, $zero, 1
		lwc1 $f1, float_zero
		add.s $f1, $f1, $f12
		j menu

addition:
	add.s $f5, $f1, $f2	#$f5 = $f1 + $f2
	j show_result
	
subtraction:
	sub.s $f5, $f1, $f2	#$f5 = $f1 - $f2	
	j show_result

multiplication:
	mul.s $f5, $f1, $f2	#$f5 = $f1 * $f2	
	j show_result

division:
	div.s $f5, $f1, $f2	#$f5 = $f1 / $f2	
	j show_result
	
inversion:
	lwc1 $f2, float_one					
	div.s $f5, $f2, $f1	#$f5 = $f2 / $f1
	j show_result
	
absolute:
	abs.s $f5, $f1		#$f5 = |$f1|
	j show_result

power:
	lwc1 $f3, float_zero
	add.s $f3, $f3, $f1
	cvt.w.s $f2, $f2
	mfc1 $t3, $f2
	power_loop:
		beq $t3, 1, end_power_loop
		mul.s $f1, $f1, $f3
		sub $t3, $t3, 1
		j power_loop
		
	end_power_loop:
	mov.s $f5, $f1	
	j show_result

factorial:
	#$f1 - operand but float
	#$f1 float => $t3 int conversion
	cvt.w.s $f1, $f1
	mfc1 $t3, $f1
	blt $t3, 0, show_error
	
	#repare number 0 and 1
	beq $t3, 1, set_to_1
	beq $t3, 0, set_to_1
	
	#$t3 - operand but int
	add $t4, $zero, $t3
	sub $t4, $t4, 1
	loop:
		beq $t4, 1, end_loop
		mul $t3, $t3, $t4
		sub $t4, $t4, 1
		j loop
	end_loop:
	#in $t1 is our result (int) now conversion to float to $f12
	mtc1 $t3, $f5
	cvt.s.w $f5, $f5
	j show_result
	
	show_error:
		print_string(err)
		j show_result
	
	set_to_1:
		addi $t3, $zero, 1
		mtc1 $t3, $f5
		cvt.s.w $f5, $f5
		j show_result
	
#MEMORY MODULE
addToMemory:
	add.s $f10, $f10, $f5
	j show_result

subtractFromMemory:	
	sub.s $f10, $f10, $f5
	j show_result
	
clearMemory:
	lwc1 $f10, float_zero
	j show_result
	
loadMemoryAsA:
	lwc1 $f1, float_zero
	add.s $f1, $f1 ,$f10
	addi $t6, $zero, 1
	j menu
	
loadMemoryAsB:
	lwc1 $f2, float_zero
	add.s $f2, $f2 ,$f10
	addi $t7, $zero, 1
	j menu
	
#END
exit:
	li $v0, 10
	syscall
	


