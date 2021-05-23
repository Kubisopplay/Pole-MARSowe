# ==========================================================================
# Reverse Polish Notation Calculator
# ==========================================================================
# RPN calculator in MIPS
#
# Inf2C-CS Coursework 1. Task B
# SOLUTION
#
# Paul Jackson
# 10 Oct 2012
        
        #==================================================================
        # DATA SEGMENT
        #==================================================================
        .data
                        # // Global variables in memory
                        # int stack[STACK_SIZE] ;
        .align 2        # // Ensure stack array starts on word boundary
stack:  .space 20       # // Allocate STACK_SIZE * 4 byte words for stack
                        # // where STACK_SIZE = 5.
stack_end:
        
                        # // String constants
prompt: .asciiz "> "    # char* prompt = "> " ;
newline:
        .asciiz "\n"    # char* newline = "\n" ; 

empty:                  # char* empty = "(EMPTY)\n" // Stack empty message
        .asciiz "(EMPTY)\n" 
colonsp:
        .asciiz ": "    # char* colonsp = ": " // For stack print formatting
        
        #==================================================================
        # TEXT SEGMENT  
        #==================================================================
        .text

        # // Register usage.
        # //
        # int* stackp ;   // $s0.  Stack pointer
        # int* stack  ;   // $s1.  &stack[0] - Start address of stack 
        # int* stack_end ;// $s2.  &stack[STACK_SIZE] - First address after
        #                 //                            end of stack
        # int  c          // $s3.  Input character (coerced to int)

        # int  s4 // $s4 Temporary var preserved across function calls
        # int  s5 // $s5 Temporary var preserved across function calls

        #------------------------------------------------------------------
        # PUSH FUNCTION
        #------------------------------------------------------------------
                              # void push (int i) 
                              # i in $a0
push:                         # {
                              #     if (stackp < stack_end) 
        slt  $t1, $s0, $s2    #         // $t1 = stackp < stack_end
        beqz $t1, push_end    #         // b push_end if $t1 == 0
                              #     {
        sw   $a0, 0($s0)      #         *stackp = i ;
        addi $s0, $s0, 4      #         ++stackp ;
                              #     }
push_end:       
        jr $ra                #     return ;
                              # }

        
        #------------------------------------------------------------------
        # POP FUNCTION
        #------------------------------------------------------------------
                                # int pop() {
  
pop:                            #     if (stack < stackp) 
        slt  $t1, $s1, $s0      #         // $t1 = stack < stackp
        beqz  $t1, pop1         #         // branch to pop1 if $t1 == 0
                                #     {
        addi $s0, $s0, -4       #         stackp-- ;
                                #         return *stackp ;
        lw   $v0, 0($s0)        #         // $v0 = *stackp
        jr   $ra                #         // return $v0
        
                                #     } else {
                                #         return 0 ;
pop1:   li   $v0, 0             #         // $v0 = 0
        jr $ra                  #         // return $v0
                                # }
        

        #------------------------------------------------------------------
        # MAIN BODY
        #------------------------------------------------------------------
main:
        # Initialisation of registers holding constant values

        la  $s1, stack            # // $s1 = &stack[0];
        la  $s2, stack_end        # // $s2 = &stack[STACK_SIZE];

        # Initialisation of registers for main program variable
        move $s0, $s1             # stackp = stack ;

        li $v0, 4                 # print_string("> ")
        la $a0, prompt
        syscall

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        # READ LOOP
        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

mainloop:                         # while (1) {

        
        li $v0, 12                #    c = read_char()
        syscall                 
        move $s3, $v0           

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        # CASE SWITCH ON INPUT CHAR
        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

maincase1:  # TEST FOR NEWLINE

        li  $t2, 0x0a             #    if (c == '\n') 
        beq $s3, $t2, print_stack #        break ;

maincase2:  # TEST FOR ENTER NEW NUMBER

        li  $t2, 'e'              #    if (c == 'e')
        bne $s3, $t2, maincase3
                                  #    {
        move $a0, $zero           #       push(0) ;
        jal push
        j maincases_end           #    } else

        
maincase3:      
        # TEST FOR DIGIT
                                  # if ('0' <= c && c <= '9') 

        li   $t1, '0'             # // $t1 = '0'
        slt  $t2, $s3, $t1        # // $t2 = c < '0'
        bnez $t2, maincase4       # // Skip case if c < '0'

        li   $t2, '9'             # // $t2 = '9'
        slt  $t3, $t2, $s3        # // $t3 = '9' < c
        bnez $t3, maincase4       # // Skip case if '9' < c
                                  # {

                                #    push (10 * pop() + (c - '0'));

        sub $s4, $s3, $t1       #    // $s4 = c - '0'
        jal pop                 #    // $v0 = pop()
        sll $t2, $v0, 1         
        sll $t3, $v0, 3
        add $t3, $t2, $t3       #    // $t3 = 10 * $v0
        add $t3, $t3, $s4       #    // $t3 = $t3 + (c - '0')
        move $a0, $t3
        jal push                #    // push $t3
        
                                # }
        j maincases_end         # else
        
maincase4:  # TEST FOR NEGATE

        li  $t2, 'n'            # if (c == 'n') 
        bne $s3, $t2, maincase5
                                # {
                                #    push(-pop());
        jal pop
        sub $a0, $zero, $v0
        jal push
        j maincases_end         # } else 
                                        
maincase5:  # TEST FOR + OPERATION

        li  $t2, '+'            # if (c == '+')
        bne $s3, $t2, maincase6
                                # {
                                #    push(pop() + pop());
        jal pop                 #    // $s4 = pop()
        move $s4, $v0
        jal pop                 #    // $v0 = pop()
        add  $a0, $s4, $v0      #    // $a0 = pop() + pop()
        jal push
        j maincases_end         # } else 

maincase6:  # TEST FOR - OPERATION

        li  $t2, '-'            # if (c == '-')
        bne $s3, $t2, maincase7
                                # {
                                #    int arg2 = pop(); // 2nd arg for -
        jal pop                 #    // $s4 = pop()  
        move $s4, $v0
                                #    int arg1 = pop(); // 1st arg for -
        jal pop                 #    // $v0 = pop()

                                #    push(arg1 - arg2);
        sub  $a0, $v0, $s4      #    // $a0 = arg1 - arg2
        jal push                #    // push($a0)

        j maincases_end         # } else 

maincase7:  # TEST FOR * OPERATION

        li  $t2, '*'            # if (c == '*')
        bne $s3, $t2, maincases_end
                                # {
                                #    push(pop() * pop());
        jal pop                 #    // $s4 = pop()
        move $s4, $v0
        jal pop                 #    // $v0 = pop()
        mul  $a0, $s4, $v0      #    // $a0 = pop() * pop()
        jal push                #    // push($a0)
                                # }        

maincases_end:
        j mainloop

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        # PRINT_STACK 
        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

print_stack:
        li    $v0, 4            #    print_string("\n") ;
        la    $a0, newline
        syscall

                                #    // This test for the stack being
                                #    // empty was not required in the submitted
                                #    // solutions.  Indeed the print code
                                #    // in the else case below functions
                                #    // correctly also when stack == stackp.

        bne  $s1, $s0, print1   #    if (stack == stackp) {

        # Uncomment following code to print a message on the stack being empty
        # 
        # li $v0, 4               #       print_string("EMPTY\n")
        # la $a0, empty
        # syscall

        j print_end
print1:                         #    else {
                                #       int * pp; // Use $s4 for pp (print ptr)
        move $s4, $s1           #       pp = stack ;

print2: beq  $s4, $s0, print_end#       while (pp != stackp) {
        
        li   $v0, 1             #          print_int(pp - stack) ;
        sub  $a0, $s4, $s1      # 
        srl  $a0, $a0, 2        # 
        syscall

        li    $v0, 4            #          print_string(": ") ;
        la    $a0, colonsp
        syscall

        li    $v0, 1            #          print_int(*pp) ;
        lw    $a0, 0($s4)
        syscall

        li    $v0, 4            #          print_string("\n") ;
        la    $a0, newline
        syscall

        add $s4, $s4, 4         #          pp++ ;
        j print2
                                #       }
                                #    }
print_end:

        li $v0, 10      # exit()#    exit() ;
        syscall

        #----------------------------------------------------------------
        # END OF CODE
        #----------------------------------------------------------------