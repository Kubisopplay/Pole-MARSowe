.macro print_string(%value)
	li $v0, 4
	la $a0, %value
	syscall 
.end_macro 

.macro print_character(%value)
	li $v0, 11
	la $a0, %value
	syscall 
.end_macro 

.data
	infix: .space 1024
	postfix: .space 1024
	operator: .space 256
	endMsg: .asciiz "Chcesz kontynuowac?"
	byeMsg: .asciiz "Do widzenia!"
	errorMsg: .asciiz "Blad wejscia"
	startMsg: .asciiz "WprowadŸ dzialanie\nDozwolone operacje: + - * / ()"
	prompt_postfix: .asciiz "Wyrazenie postfixowe: "
	prompt_result: .asciiz "Rezultat: "
	prompt_infix: .asciiz "Wyrazenie infixowe: "
	converter: .word 1
	wordToConvert: .word 1
	float_one: .float 1.0
	stack: .float
	
.text
start:
	# Bierzemy wyra¿enie w zwyk³ej postaci infixowej 2+2-3 itd.
	li $v0, 54		# syscall numer: 54 Okienko pobieraj¹ce String
	la $a0, startMsg	# $a0 £adujemy wiadomoœæ dla u¿ytkownika
	la $a1, infix		# $a1 Adres buforu wejœcia
 	la $a2, 256		# $a2 okreœlenie maksymalnej liczby znaków do wczytania
 	syscall			
 	beq $a1,-2,end		# $a1 dopuszcza wartoœci: 0 - OK | -2 - Cancel | -3 OK ale bez danych|
 	beq $a1,-3,start	# -4 - za d³ugi string wejœciowy


# Drukowanie w postaci infixowej
	print_string(prompt_infix)
	print_string(infix)
	print_character('\n')

# Status ==========================================================================================
	li $s7,0		# Status 
				# 0 = initially receive nothing w sumie to nic 
				# 1 = odbierz liczbe
				# 2 = odbierz operator +-/*
				# 3 = odbierz lewy nawias (
				# 4 = odbierz prawy nawias )
	li $t9,0		# Licznik cyfr - Count digit
	li $t5,-1		# Postfix top offset
	li $t6,-1		# Operator top offset
	la $t1, infix		# Infix current byte address +1 each loop
	la $t2, postfix
	la $t3, operator	
	addi $t1,$t1,-1		# Ustaw adres startowy infixu na -1
# Konwersja na postfix =============================================================================
scanInfix: 			# PrzejdŸ przez ka¿dy znak w postaci infixowej
				# Sprawdzamy wszystkie poprawne opcje wejœciowe
	addi $t1,$t1,1			# Zwiêksz pozycje infixow¹
	lb $t4, ($t1)			# Wczytaj obecne wejœcie infixowe
	beq $t4, ' ', scanInfix		# Jeœli spacja to zignoruj i skanuj dalej
	beq $t4, '\n', EOF		# Skanowanie koñca ci¹gu wejœcia, => przeniesienie operatorów do postifxa
	
	beq $t9,1,DigitDeployToPostfix		# If state is 1 digit

	
	beq $t4,'0',store1Digit
	beq $t4,'1',store1Digit
	beq $t4,'2',store1Digit
	beq $t4,'3',store1Digit
	beq $t4,'4',store1Digit
	beq $t4,'5',store1Digit
	beq $t4,'6',store1Digit
	beq $t4,'7',store1Digit
	beq $t4,'8',store1Digit
	beq $t4,'9',store1Digit
	
	continueScan:			
	beq $t4, '+', AdditionSubtraction
	beq $t4, '-', AdditionSubtraction
	beq $t4, '*', MultiplicationDivision
	beq $t4, '/', MultiplicationDivision
	beq $t4, '^', Exponential 		
	beq $t4, '(', openBracket
	beq $t4, ')', closeBracket
	
wrongInput:			# Wykrycie b³êdu wejœcia
	li $v0, 55		# Syscall 55: MessageDialog
 	la $a0, errorMsg	# Wiadomoœæ o b³êdzie
 	li $a1, 2		# $a1 (2) wiadomoœæ typu warning	
 	syscall
 	j ask	
	
DigitDeployToPostfix:		#stan 2 mamy liczbê do dodania do postfixu
	jal numberToPost
	j continueScan		#kontynuujemy skan w poszukiwaniu operatórów +-/*

store1Digit:
	beq $s7,4,wrongInput		# odbieramy cyfrê po znaku: )
	addi $s4,$t4,-48		# Przechowaj pierwsz¹ cyfrê jako liczbê
	add $t9,$zero,1			# Zmiana statusu na 1 cyfrê w pamieci
	li $s7,1
	j scanInfix			#skanujemy od nowa
	
numberToPost:
	beq $t9,0,endnumberToPost
	addi $t5,$t5,1
	add $t8,$t5,$t2			
	sb $s4,($t8)			# Chowaj cyfre w postfixie
	add $t9,$zero,$zero		# Zmiana statusu na 0, nie mamy cyfr do wys³ania na postfix
	endnumberToPost:
	jr $ra
		
#####################################################################################################
#KONIEC SEKCJI SKANOWANIA WYRA¯EÑ INFIXOWYCH ######## START SEKCJI OBLICZANIA WYRA¯ENIA POSTFIXOWEGO#
#####################################################################################################
 	 	 	 	 	 	 		 	 	 	 	 	 	 	
finishScan:
	
# Calculate
	li $t9,-4		# Ustaw przesniêcie wska¿nika szczytu stosu na -4
	la $t3,stack		# £adujemy adres stosu
	li $t6,-1		# £aduj przesuniecie postfixu do -1
	l.s $f0,converter	# Wczytaj konwerter
calPost:
	addi $t6,$t6,1		# Przesuwamy siê po postfixie 
	add $t8,$t2,$t6		# Wczytujemy adres obecnego znaku postfixu
	lbu $t7,($t8)		# Wczytujemy jego wartoœæ
	bgt $t6,$t5,printResult	# Liczymy dla wszystkich --> drukuj
	bgt $t7,99,calculate	# If current Postfix > 99 --> an operator --> popout 2 number to calculate
	# If not then current Postfix is a number
	addi $t9,$t9,4		# Obecny wskaŸnik na stos
	add $t4,$t3,$t9		# Adres szczytu stosu
	sw $t7,wordToConvert	
	l.s $f10,wordToConvert	# Wczytaj liczbe do kooprocka konwersja na float
	div.s $f10,$f10,$f0	
	s.s $f10,($t4)		# Po³ó¿ na stos
	sub.s $f10,$f10,$f10	# Reset f10
	j calPost		# PÊTLA, wracamy
	
	calculate:
		# Zwróæ 1 liczbe
		add $t4,$t3,$t9		
		l.s $f3,($t4)
		# wypluj nastêpna liczbe
		addi $t9,$t9,-4
		add $t4,$t3,$t9		
		l.s $f2,($t4)
		# dekodowanie operatorów
		beq $t7,143,plus
		beq $t7,145,minus
		beq $t7,142,multiply
		beq $t7,147,divide
		beq $t7,194,power
		
		clearing:
		sub.s $f2,$f2,$f2	# Reset f2 f3
		sub.s $f3,$f3,$f3	# $f3 = 0
		j calPost
		
		plus:				# Dodawanie
			add.s $f1,$f2,$f3	# $f1 = $f2 + $f3
			s.s $f1,($t4)	
			j clearing
		minus:				#Odejmowanie
			sub.s $f1,$f2,$f3	# $f1 = $f2 - $f3
			s.s $f1,($t4)	
			j clearing
		multiply:
			mul.s $f1,$f2,$f3
			s.s $f1,($t4)
			j clearing
		divide:
			div.s $f1,$f2,$f3
			s.s $f1,($t4)
			j clearing
		power:
			#f2 ^ f3
			lwc1 $f4, float_one
			
			sub.s $f5, $f5, $f5
			add.s $f5, $f5, $f2
			
			power_loop:
				c.eq.s  $f3, $f4
				bc1t end_power_loop
				
				mul.s $f2, $f2, $f5
				sub.s $f3, $f3, $f4
				j power_loop
		
			end_power_loop:
			s.s $f2,($t4)
			j clearing
					
	
	

		
printResult:	
	li $v0, 4
	la $a0, prompt_result
	syscall
	li $v0, 2
	l.s $f12,($t4)
	syscall
	li $v0, 11
	li $a0, '\n'
	syscall
ask: 			# Pytaj u¿ytkownika o kontynuowanie
 	li $v0, 50	# Syscall 50: ConfirmDialog
 	la $a0, endMsg	# $a0 wiadomosc do u¿ytkownika
 	syscall
 	beq $a0,0,start	# 0 - YES
 	beq $a0,2,ask	# 1 - NO






# End program
end:
 	li $v0, 55	# Syscall 55: MessageDialog
 	la $a0, byeMsg	# $a0 wiadomosc po¿egnalna 
 	li $a1, 1	# $a1 (1) - wiadomoœæ informacyjna
 	syscall
 	li $v0, 10	# KONIEC PROGRAMU
 	syscall
 
#Podprogramy
EOF:
	beq $s7,2,wrongInput			# Jeœli input konczy sie operatorem lub lewym nawiasem (
	beq $s7,3,wrongInput			#
	beq $t5,-1,wrongInput			# Pusty input
	j popAll

	
AdditionSubtraction:			# Input is + -
	beq $s7,2,wrongInput		# Receive operator after operator or open bracket
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		# Receive operator before any number
	li $s7,2			# Change input status to 1
	continuePlusMinus:
	beq $t6,-1,inputToOp		# There is nothing in Operator stack --> push into
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',inputToOp		# If top is ( --> push into
	beq $t7,'+',equalPrecedence	# If top is + -
	beq $t7,'-',equalPrecedence
	beq $t7,'*',lowerPrecedence	# If top is * /
	beq $t7,'/',lowerPrecedence
	beq $t7,'^',lowerPrecedence	#####################################
	
MultiplicationDivision:			# Input is * /
	beq $s7,2,wrongInput		# Receive operator after operator or open bracket
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		# Receive operator before any number
	li $s7,2			# Change input status to 1
	beq $t6,-1,inputToOp		# There is nothing in Operator stack --> push into
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',inputToOp		# If top is ( --> push into
	beq $t7,'+',inputToOp		# If top is + - --> push into
	beq $t7,'-',inputToOp
	beq $t7,'*',equalPrecedence	# If top is * /
	beq $t7,'/',equalPrecedence
	beq $t7,'^',inputToOp		#######################################################
	
Exponential:	###########################################
	beq $s7,2,wrongInput		# Receive operator after operator or open bracket
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		# Receive operator before any number
	li $s7,2			# Change input status to 1
	beq $t6,-1,inputToOp		# There is nothing in Operator stack --> push into
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',inputToOp		# If top is ( --> push into
	beq $t7,'+',inputToOp		# If top is + - --> push into
	beq $t7,'-',inputToOp
	beq $t7,'*',inputToOp		# If top is * /
	beq $t7,'/',inputToOp
	beq $t7,'^',equalPrecedence

openBracket:			# Input is (
	beq $s7,1,wrongInput		# Receive open bracket after a number or close bracket
	beq $s7,4,wrongInput
	li $s7,3			# Change input status to 1
	j inputToOp
closeBracket:			# Input is )
	beq $s7,2,wrongInput		# Receive close bracket after an operator or operator
	beq $s7,3,wrongInput	
	li $s7,4
	add $t8,$t6,$t3			# Load address of top Operator 
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',wrongInput		# Input contain () without anything between --> error
	continueCloseBracket:
	beq $t6,-1,wrongInput		# Can't find an open bracket --> error
	add $t8,$t6,$t3			# Load address of top Operator
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',matchBracket	# Find matched bracket
	jal opToPostfix			# Pop the top of Operator to Postfix
	j continueCloseBracket		# Then loop again till find a matched bracket or error			
equalPrecedence:	# Mean receive + - and top is + - || receive * / and top is * /
	jal opToPostfix			# Pop the top of Operator to Postfix
	j inputToOp			# Push the new operator in
lowerPrecedence:	# Mean receive + - and top is * /
	jal opToPostfix			# Pop the top of Operator to Postfix
	j continuePlusMinus		# Loop again
inputToOp:			# Push input to Operator
	add $t6,$t6,1			# Increment top of Operator offset
	add $t8,$t6,$t3			# Load address of top Operator 
	sb $t4,($t8)			# Store input in Operator
	j scanInfix
opToPostfix:			# Pop top of Operator in push into Postfix
	addi $t5,$t5,1			# Increment top of Postfix offset
	add $t8,$t5,$t2			# Load address of top Postfix 
	addi $t7,$t7,100		# Encode operator + 100
	sb $t7,($t8)			# Store operator into Postfix
	addi $t6,$t6,-1			# Decrement top of Operator offset
	jr $ra
matchBracket:			# Discard a pair of matched brackets
	addi $t6,$t6,-1			# Decrement top of Operator offset
	j scanInfix
popAll:				# Pop all Operator to Postfix
	jal numberToPost
	beq $t6,-1,finishScan		# Operator empty --> finish
	add $t8,$t6,$t3			# Load address of top Operator 
	lb $t7,($t8)			# Load byte value of top Operator
	beq $t7,'(',wrongInput		# Unmatched bracket --> error
	beq $t7,')',wrongInput
	jal opToPostfix
	j popAll			# Loop till Operator empty

	


