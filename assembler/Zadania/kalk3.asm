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
	startMsg: .asciiz "Wprowad� dzialanie\nDozwolone operacje: + - * / ()"
	prompt_postfix: .asciiz "Wyrazenie postfixowe: "
	prompt_result: .asciiz "Rezultat: "
	prompt_infix: .asciiz "Wyrazenie infixowe: "
	converter: .word 1
	wordToConvert: .word 1
	float_one: .float 1.0
	float_zero: .float 0.0
	stack: .float
	
.text
start:
	# Bierzemy wyra�enie w zwyk�ej postaci infixowej 2+2-3 itd.
	li $v0, 54		# syscall numer: 54 Okienko pobieraj�ce String
	la $a0, startMsg	# $a0 �adujemy wiadomo�� dla u�ytkownika
	la $a1, infix		# $a1 Adres buforu wej�cia
 	la $a2, 256		# $a2 okre�lenie maksymalnej liczby znak�w do wczytania
 	syscall			
 	beq $a1,-2,end		# $a1 dopuszcza warto�ci: 0 - OK | -2 - Cancel | -3 OK ale bez danych|
 	beq $a1,-3,start	# -4 - za d�ugi string wej�ciowy


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
scanInfix: 			# Przejd� przez ka�dy znak w postaci infixowej
				# Sprawdzamy wszystkie poprawne opcje wej�ciowe
	addi $t1,$t1,1			# Zwi�ksz pozycje infixow�
	lb $t4, ($t1)			# Wczytaj obecne wej�cie infixowe
	beq $t4, ' ', scanInfix		# Je�li spacja to zignoruj i skanuj dalej
	beq $t4, '\n', EndOfInput		# Skanowanie ko�ca ci�gu wej�cia, => przeniesienie operator�w do postifxa
	beq $t9,1,DigitDeployToPostfix		# Je�li stan jest 1 to schowaj liczbe w postfixie
	beq $t4,'0',storeDigit
	beq $t4,'1',storeDigit
	beq $t4,'2',storeDigit
	beq $t4,'3',storeDigit
	beq $t4,'4',storeDigit
	beq $t4,'5',storeDigit
	beq $t4,'6',storeDigit
	beq $t4,'7',storeDigit
	beq $t4,'8',storeDigit
	beq $t4,'9',storeDigit
	scanForOperators:			
	beq $t4, '+', AdditionSubtraction
	beq $t4, '-', AdditionSubtraction
	beq $t4, '*', MultiplicationDivision
	beq $t4, '/', MultiplicationDivision
	beq $t4, '^', Exponential 		
	beq $t4, '!', FactorialScan 		
	beq $t4, '(', openBracket
	beq $t4, ')', closeBracket
	
wrongInput:			# Wykrycie b��du wej�cia
	li $v0, 55		# Syscall 55: MessageDialog
 	la $a0, errorMsg	# Wiadomo�� o b��dzie
 	li $a1, 2		# $a1 (2) wiadomo�� typu warning	
 	syscall
 	j ask	
	
DigitDeployToPostfix:		#stan 2 mamy liczb� do dodania do postfixu
	jal numberToPost
	j scanForOperators		#kontynuujemy skan w poszukiwaniu operat�r�w +-/*

storeDigit:
	beq $s7,4,wrongInput		# odbieramy cyfr� po znaku: )
	addi $s4,$t4,-48		# Przechowaj pierwsz� cyfr� jako liczb�
	add $t9,$zero,1			# Zmiana statusu na 1 cyfr� w pamieci
	li $s7,1			# status odbierania liczby
	j scanInfix			# skanujemy od nowa
	
numberToPost:				# wysy�anie cyfry do postifxa
	beq $t9,0,endnumberToPost	# je�li cyfry nie ma to jej nie wysy�amy OCZYWISTE
	addi $t5,$t5,1			# przesu� si� o 1 po postfixie
	add $t8,$t5,$t2			# 
	sb $s4,($t8)			# Chowaj cyfre w postfixie
	add $t9,$zero,$zero		# Zmiana statusu na 0, nie mamy cyfr do wys�ania na postfix
	endnumberToPost:
	jr $ra				# WRACAMY WRACAMY !!!!
		
#####################################################################################################
#KONIEC SEKCJI SKANOWANIA WYRA�E� INFIXOWYCH ######## START SEKCJI OBLICZANIA WYRA�ENIA POSTFIXOWEGO#
#####################################################################################################
 	 	 	 	 	 	 		 	 	 	 	 	 	 	
finishScan:			# LICZYMY
	li $t9,-4		# Ustaw przesni�cie wska�nika szczytu stosu na -4
	la $t3,stack		# �adujemy adres stosu
	li $t6,-1		# �aduj przesuniecie postfixu do -1
	l.s $f0,converter	# Wczytaj konwerter
calPost:
	addi $t6,$t6,1		# Przesuwamy si� po postfixie 
	add $t8,$t2,$t6		# Wczytujemy adres obecnego znaku postfixu
	lbu $t7,($t8)		# Wczytujemy jego warto��
	bgt $t6,$t5,printResult	# Liczymy dla wszystkich --> drukuj
	bgt $t7,99,calculate	# Je�li postfix > 99 --> mamy do czynienia z operatorem
	# Je�li postfixowy element nie jest liczb�
	addi $t9,$t9,4		# Obecny wska�nik na stos
	add $t4,$t3,$t9		# Adres szczytu stosu
	sw $t7,wordToConvert	
	l.s $f10,wordToConvert	# Wczytaj liczbe do kooprocka konwersja na float
	div.s $f10,$f10,$f0	
	s.s $f10,($t4)		# Po�� na stos
	sub.s $f10,$f10,$f10	# Reset f10
	j calPost		# P�TLA, wracamy
	
	calculate:
		# Zwr�� 1 liczbe
		add $t4,$t3,$t9		
		l.s $f3,($t4)
		
		#############################################
		beq $t7,133,factorial #dangerous code########
		#############################################
		
		# wypluj nast�pna liczbe
			addi $t9,$t9,-4
			add $t4,$t3,$t9		
			l.s $f2,($t4)
			
		# dekodowanie operator�w
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
		factorial:
			#$f3!		
			#0! = 1 
			lwc1 $f4, float_zero
			c.eq.s $f3, $f4
			bc1t set_to_1 
			
			#1! = 1 
			lwc1 $f4, float_one
			c.eq.s $f3, $f4
			bc1t set_to_1 
	
			sub.s $f2, $f2, $f2
			add.s $f2, $f2, $f3
			sub.s $f2, $f2, $f4
			loop:
				c.eq.s $f2, $f4
				bc1t end_loop
				mul.s $f3, $f3, $f2
				sub.s $f2, $f2, $f4
			j loop
			end_loop:
			s.s $f3,($t4)
			j clearing

			set_to_1:
				lwc1 $f3, float_one
				s.s $f3,($t4)
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
ask: 			# Pytaj u�ytkownika o kontynuowanie
 	li $v0, 50	# Syscall 50: ConfirmDialog
 	la $a0, endMsg	# $a0 wiadomosc do u�ytkownika
 	syscall
 	beq $a0,0,start	# 0 - YES
 	beq $a0,2,ask	# 1 - NO






# End program
end:
 	li $v0, 55	# Syscall 55: MessageDialog
 	la $a0, byeMsg	# $a0 wiadomosc po�egnalna 
 	li $a1, 1	# $a1 (1) - wiadomo�� informacyjna
 	syscall
 	li $v0, 10	# KONIEC PROGRAMU
 	syscall
 
#Podprogramy
#Koniec wprowadzania wej�cia
EndOfInput:
	beq $s7,2,wrongInput			# Je�li input konczy sie operatorem lub lewym nawiasem (
	beq $s7,3,wrongInput			#
	beq $t5,-1,wrongInput			# Pusty input
	j popAll
#####################################################################################################
#OBS�UGA OPERATOR�W##################################################################################
#####################################################################################################
AdditionSubtraction:			# Otrzymujemy + -
	beq $s7,2,wrongInput		# obs�uga sytuacji ++ lub )+
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		# odbieranie opreatora przed jak�kolwiek liczb�
	li $s7,2			# Zmie� status wej�cia na 1 - w�asnie uzyska�e� operator
	continuePlusMinus:
	beq $t6,-1,inputToOp		# Nie ma nic na stosie operacji --> puszujemy
	add $t8,$t6,$t3			# Wczytaj adres operatora na szczycie
	lb $t7,($t8)			# Wczytaj warto�� operatora na szczycie
	beq $t7,'(',inputToOp		# Je�li na g�rze jest ( --> puszujemy
	beq $t7,'+',equalPrecedence	# Na szczycie jest + -
	beq $t7,'-',equalPrecedence
	beq $t7,'*',lowerPrecedence	# Szczyt to * / ^ !
	beq $t7,'/',lowerPrecedence
	beq $t7,'^',lowerPrecedence	
	beq $t7,'!',lowerPrecedence	
	
MultiplicationDivision:			# Na wej�ciu * /
	beq $s7,2,wrongInput		# INSTRUKCJE ROBI� TO SAMO CO WY�EJ
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		
	li $s7,2			
	beq $t6,-1,inputToOp		
	add $t8,$t6,$t3			
	lb $t7,($t8)			
	beq $t7,'(',inputToOp		
	beq $t7,'+',inputToOp		
	beq $t7,'-',inputToOp
	beq $t7,'*',equalPrecedence	
	beq $t7,'/',equalPrecedence
	beq $t7,'^',inputToOp		
	beq $t7,'!',inputToOp		
	
Exponential:				#Na wej�ciu maj� znak ^
	beq $s7,2,wrongInput		
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		
	li $s7,2			
	beq $t6,-1,inputToOp		
	add $t8,$t6,$t3			
	lb $t7,($t8)			
	beq $t7,'(',inputToOp		
	beq $t7,'+',inputToOp		
	beq $t7,'-',inputToOp
	beq $t7,'*',inputToOp		
	beq $t7,'/',inputToOp		
	beq $t7,'^',equalPrecedence	
	beq $t7,'!',inputToOp		
FactorialScan: 				# operator !
	beq $s7,2,wrongInput		
	beq $s7,3,wrongInput
	beq $s7,0,wrongInput		
	#li $s7,2			# NIE ZMIENIAMY STATUSU ISTNIENIA OPERATORA DZIA�ANIE 5!-2 JEST POPRAWNE
	beq $t6,-1,inputToOp		
	add $t8,$t6,$t3			
	lb $t7,($t8)			
	beq $t7,'(',inputToOp		
	beq $t7,'+',inputToOp		
	beq $t7,'-',inputToOp
	beq $t7,'*',inputToOp		
	beq $t7,'/',inputToOp
	beq $t7,'^',inputToOp
	beq $t7,'!',equalPrecedence
openBracket:			# Na wej�ciu mamy (
	beq $s7,1,wrongInput		# ( po cyfrze lub )
	beq $s7,4,wrongInput
	li $s7,3			# status na 3
	j inputToOp
closeBracket:			# Na wej�ciu mamy )
	beq $s7,2,wrongInput		# ) po operatorze
	beq $s7,3,wrongInput	
	li $s7,4			
	add $t8,$t6,$t3			
	lb $t7,($t8)			
	beq $t7,'(',wrongInput		# mamy () bez niczego w �rodku wi�c ERROR
	continueCloseBracket:
	beq $t6,-1,wrongInput		# NIE MA NAWIASU OTWIERAJ�CEGO wi�c ERRRRROOR
	add $t8,$t6,$t3			
	lb $t7,($t8)			
	beq $t7,'(',matchBracket	# SZUKAMY PASUJ�CEGO NAWIASU
	jal opToPostfix			# przerzu� g�re operator�w do postfixu
	j continueCloseBracket		# loopujem dalej a� znajdziemy pasuj�cy nawias, inaczej error
	
#####################################################################################################
#OBS�UGA OPERATOR�W POWY�EJ##########################OBS�UGA HIERARCHII DZIA�A� PONI�EJ##############
#####################################################################################################
	
equalPrecedence:	# Otrzymali�my + - i na szczycie jest + - LUB mamy * / a nad nim jest * /
	jal opToPostfix			# Wrzu� operator do postfixu
	j inputToOp			# pchnij nowy operator do �rodka
	
lowerPrecedence:	# Otrzymali�mye + - na szczycie jest * /
	jal opToPostfix			# wrzu� operatory do postfixa
	j continuePlusMinus		# Loopujemy znowu
	
inputToOp:				# Wej�cie do operatora
	add $t6,$t6,1			# Zwi�ksz przesuni�cie operatora
	add $t8,$t6,$t3			# Wczytaj adres szczytu operatora
	sb $t4,($t8)			# Trzymaj wej�cie w operatorze
	j scanInfix			# Wracamy do skanowania
	
opToPostfix:				# Wrzucanie operatora do postfixa
	addi $t5,$t5,1			# Zwi�ksz przesuni�cie po postfixie
	add $t8,$t5,$t2			# Wczytaj adres szczytu postfixu
	#addi $t7,$t7,100		# Encode operator + 100#################################################
	sb $t7,($t8)			# Przechowaj operator w postfixie
	addi $t6,$t6,-1			# Zmniejsz przesuniecie po operatorze
	jr $ra				# Wracamy wracamy
	
matchBracket:				# szuakmy pasuj�cego nawiasu
	addi $t6,$t6,-1			# zmniejsz przesuniecie po operatorze
	j scanInfix
	
popAll:					# Wrzu� wszystkie operatory do postfixa
	jal numberToPost
	beq $t6,-1,finishScan		# nie ma operator�w to koniec skanu
	add $t8,$t6,$t3			# wczytaj adres szczytu operatora
	lb $t7,($t8)			# Wczytaj wartosc operatora
	beq $t7,'(',wrongInput		# nie pasuj�cy nawias wiec error
	beq $t7,')',wrongInput
	jal opToPostfix
	j popAll			# zap�tlamy dop�ki s� operatory

	


