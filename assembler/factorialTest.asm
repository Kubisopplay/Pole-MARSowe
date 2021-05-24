.data
	l: .float 1.0
	float_zero: .float 0.0
	float_one: .float 1.0
.text
#$f3!
	lwc1 $f3, l		
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
	jal end

set_to_1:
	lwc1 $f3, float_one
	#jal end_loop
	jal end
end:
		