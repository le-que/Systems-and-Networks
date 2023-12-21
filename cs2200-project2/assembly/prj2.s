! Spring 2022 Revisions by Andrej Vrtanoski

! This program executes pow as a test program using the LC 22 calling convention
! Check your registers ($v0) and memory to see if it is consistent with this program

! vector table
vector0:
        .fill 0x00000000                        ! device ID 0
        .fill 0x00000000                        ! device ID 1
        .fill 0x00000000                        ! ...
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000                        ! device ID 7
        ! end vector table

main:	lea $sp, initsp                         ! initialize the stack pointer
        lw $sp, 0($sp)                          ! finish initialization

        lea $t0, vector0                        ! DONE: Install timer interrupt handler into vector table
        lea $t1, timer_handler
        sw  $t1, 0($t0)

        lea $t1, toaster_handler                ! DONE: Install toaster interrupt handler into vector table
        sw  $t1, 1($t0)

        lea $t0, minval
        lw $t0, 0($t0)
        addi $t1, $zero, 65534                  ! store 0000ffff into minval (to make comparisons easier)
        sw $t1, 0($t0)

        ei                                      ! Enable interrupts

        lea $a0, BASE                           ! load base for pow
        lw $a0, 0($a0)
        lea $a1, EXP                            ! load power for pow
        lw $a1, 0($a1)
        lea $at, POW                            ! load address of pow
        jalr $ra, $at                           ! run pow
        lea $a0, ANS                            ! load base for pow
        sw $v0, 0($a0)

        halt                                    ! stop the program here
        addi $v0, $zero, -1                     ! load a bad value on failure to halt

BASE:   .fill 2
EXP:    .fill 8
ANS:	.fill 0                                 ! should come out to 256 (BASE^EXP)

POW:    addi $sp, $sp, -1                       ! allocate space for old frame pointer
        sw $fp, 0($sp)

        addi $fp, $sp, 0                        ! set new frame pointer

        bgt $a1, $zero, BASECHK                 ! check if $a1 is zero
        br RET1                                 ! if the exponent is 0, return 1

BASECHK:bgt $a0, $zero, WORK                    ! if the base is 0, return 0
        br RET0

WORK:   addi $a1, $a1, -1                       ! decrement the power
        lea $at, POW                            ! load the address of POW
        addi $sp, $sp, -2                       ! push 2 slots onto the stack
        sw $ra, -1($fp)                         ! save RA to stack
        sw $a0, -2($fp)                         ! save arg 0 to stack
        jalr $ra, $at                           ! recursively call POW
        add $a1, $v0, $zero                     ! store return value in arg 1
        lw $a0, -2($fp)                         ! load the base into arg 0
        lea $at, MULT                           ! load the address of MULT
        jalr $ra, $at                           ! multiply arg 0 (base) and arg 1 (running product)
        lw $ra, -1($fp)                         ! load RA from the stack
        addi $sp, $sp, 2

        br FIN                                  ! unconditional branch to FIN

RET1:   add $v0, $zero, $zero                   ! return a value of 0
	addi $v0, $v0, 1                        ! increment and return 1
        br FIN                                  ! unconditional branch to FIN

RET0:   add $v0, $zero, $zero                   ! return a value of 0

FIN:	lw $fp, 0($fp)                          ! restore old frame pointer
        addi $sp, $sp, 1                        ! pop off the stack
        jalr $zero, $ra

MULT:   add $v0, $zero, $zero                   ! return value = 0
        addi $t0, $zero, 0                      ! sentinel = 0
AGAIN:  add $v0, $v0, $a0                       ! return value += argument0
        addi $t0, $t0, 1                        ! increment sentinel
        blt $t0, $a1, AGAIN                     ! while sentinel < argument, loop again
        jalr $zero, $ra                         ! return from mult

timer_handler:
        addi $sp, $sp, -1                       ! allocate space for $k0
        sw $k0, 0($sp)                          ! save $k0
        ei                                      ! enable interrupts
        addi $sp, $sp, -2                       ! allocate space to save processor registers

        sw $t0, 1($sp)                          ! save $t0
        sw $t1, 0($sp)                          ! save $t1

        lea $t0, ticks                          ! load addr of ticks into $t0
        lw $t0, 0($t0)                          ! load 0xFFFF into $t0
        lw $t1, 0($t0)                          ! load value of 0xFFFF (ticks) into $t1
        addi $t1, $t1, 1                        ! increment value of ticks
        sw $t1, 0($t0)                          ! store incremented value back into ticks

        lw $t0, 1($sp)                          ! restore $t0
        lw $t1, 0($sp)                          ! restore $t1
        addi $sp, $sp, 2                        ! pop stack pointer
        di                                      ! disable int
        lw $k0, 0($sp)                          ! restore $k0
        addi $sp, $sp, 1                        ! pop stack pointer
        reti                                    ! return

toaster_handler:
        ! retrieve the data from the device and check if it is a minimum or maximum value
        ! then calculate the difference between minimum and maximum value
        ! (hint: think about what ALU operations you could use to implement subract using 2s compliment)
	add $zero, $zero, $zero
	addi $sp, $sp, -1                       ! allocate space for $k0
        sw $k0, 0($sp)                          ! save $k0
        ei                                      ! enable interrupts

        addi $sp, $sp, -3                       ! allocate space to save processor registers
        sw $t0, 2($sp)                          ! save $t0
        sw $t1, 1($sp)                          ! save $t1
	sw $t2, 0($sp)				! save $t2

    	in $t0, 0x1                 		! obtain value from toaster

    	lea $t1, maxval				
    	lw $t1, 0($t1)				! get address of maxval
    	lw $t2, 0($t1)				! get value of maxval
   	bgt $t0, $t2, end			! compare toaster and value

    	lea $t1, minval
    	lw $t1, 0($t1)				! get address of minval
    	lw $t2, 0($t1)				! get value of minval
   	bgt $t2, $t0, end			! compare toaster and value

end:
    	sw $t0, 0($t1)
    	lea $t0, range
    	lw  $t0, 0($t0)                		! address of range

    	lea $t1, maxval
    	lw $t1, 0($t1)
    	lw $t1, 0($t1)

    	lea $t2, minval
    	lw $t2, 0($t2)
    	lw $t2, 0($t2)

    	nand $t2, $t2, $t2			! start of subtraction
    	addi $t2, $t2, 1
    	add $t1, $t1, $t2

    	sw $t1, 0($t0)                		! put difference in range

    	lw $t2, 0($sp)				! restore registers
    	lw $t1, 1($sp)                          
    	lw $t0, 2($sp)
    	addi $sp, $sp, 3                        ! pop stack pointer
    	di                                      ! disable int
    	lw $k0, 0($sp)                          ! restore $k0
    	addi $sp, $sp, 1                        ! pop stack pointer
    	reti                                    ! return
	
initsp: .fill 0xA000
ticks:  .fill 0xFFFF
range:  .fill 0xFFFE
maxval: .fill 0xFFFD
minval: .fill 0xFFFC