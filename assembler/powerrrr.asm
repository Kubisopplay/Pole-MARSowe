.data
	number: .float 5
	exp: .float 3
	float_one: .float 1
.text

			#swc1 $f1, number
			#swc1 $f2, exp
			lwc1 $f1, number
			lwc1 $f2, exp
			lwc1 $f4, float_one
			
			sub.s $f3, $f3, $f3  	# $f3 = 0
			
			add.s $f3, $f3, $f1	# $f3 = $f1
			# $f2 - exponent
			
			power_loop:
				c.eq.s  $f2, $f4
				bc1t end_power_loop
				
				mul.s $f1, $f1, $f3
				sub.s $f2, $f2, $f4
				j power_loop
		
			end_power_loop:
				
			