RS equ P3.1
E  equ P3.0
functionset equ 38h ; Instruction to set LCD to display 
;characters on a 5x7 matrix
displayONoff equ 0Eh  ; Instruction to turn on the LCD
cleardisplay equ 01h ; Instruction to clear the LCD
fistLineCursor equ 80h ; Positioning the cursor on the first line
secondLineCursor equ 0C0h  ; Positioning the cursor on the second line
	
org 0000h
; Initialize variables and set buttons as not pressed
mov R0,#20 ; Reference voltage in the room
setb P0.0 ; Set button 1 as not pressed
setb P0.1  ; Set button 2 as not pressed

; Call functions to initialize and display on the LCD
acall LCD ; Initialize LCD
acall first_row_text ; Display message on the first line
acall second_row_text  ; Display message on the second line
acall ADC ; Read temperature from ADC

LCD:
//Initializare LCD
	mov a,#functionset 	; Set LCD to display characters on a 5x7 matrix
	acall instructiuni
	acall delay
	
	mov a,#displayONoff	; Turn on the LCD
	acall instructiuni
	acall delay
	
	mov a,#cleardisplay	; Clear the LCD
	acall instructiuni
	acall delay

	mov a,#fistLineCursor; Position the cursor on the first line at position 0
	acall instructiuni
	acall delay
 ; Display a message on the first line
first_row_text:
	mov dptr,#0900h; Point to the memory location containing the message
	mov R1,#0h  ; Initialize loop counter
iar2:	
	mov a,#0h  ; Clear accumulator A
	movc a, @a+dptr ; Read character from memory
	inc dptr   ; Increment memory pointer
	inc r1 ; Increment loop counter
	acall date ; Send character to LCD
	acall delay ; Delay for stability
	cjne r1,#0Eh,iar2 ; Continue loop until all characters
ret

; Display the message "Temp.setata" on the second line
second_row_text:
	mov a,#secondLineCursor ; Position the cursor on the second line at position 0				;Pozitionare cursor pe linia a doua la pozitia 0
	acall instructiuni
	acall delay
	mov dptr,#0500h ; Point to the memory location containing the message
	mov R1,#0h ; Initialize loop counter
iar3:	
	mov a,#0h ; Clear accumulator A
	movc a, @a+dptr ; Read character from memory
	inc dptr  ; Increment memory pointer
	inc r1 ; Increment loop counter
	acall date ; Send character to LCD
	acall delay ; Delay for stability
	cjne r1,#0Eh,iar3
	acall show_set_temp ; Display the set temperature
ret
; Send instruction to LCD data pins
instructiuni: 	
	mov P2,a 
	acall enable_instructiuni
	ret
; Enable instructions on the LCD	
enable_instructiuni:
	clr RS 	;RS=0 for instructions
	setb E 	  ; Enable E pin								;E=1 se activeaza pinul E
	acall delay ; Delay for stability
	clr E  ; Disable E pin									;E=0 se dezactiveaza pinul E
	ret
	

date: ;Scrie date pe LCD
	mov P2,a 
	acall enable_date
	ret
	
enable_date:
	setb RS ;RS=1 pentru date
	setb E	;Rs=1 se activeaza pinul E
	acall delay
	clr E ;E=0 se dezactiveaza pinul E
	ret
	

ADC:
	
	acall readtemp
	acall show_current_temp
	
	acall temp_control
	acall relay
	sjmp adc
readtemp:
	setb P3.6; we give a command to ADC in order to 'start' a conversion
	nop
	nop ; wait some time
	nop

	clr P3.6; we stop the 'start' conversion
	
	waitEOC_low:				
		jb P3.2, waitEOC_low; we wait for 'EOC' pin to be LOW
	waitEOC_high:
		jnb P3.2, waitEOC_high	; we wait for 'EOC' pin to be HIGH again
		
	setb P3.7 ;setting P3.7 we enable the 'OE' of the ADC
	nop
	nop
	nop

	mov A, P1; store in A what we have on P1
    clr P3.7; disable 'OE' of the ADC
	mov B, #5 ; because 1 Celsius Degree represents 5 LSB on ADC,
	div AB	; we want to divide to those 5 LSB in order to find the temperature
	mov r6, a	; salvam in r6 temperatura citita
ret
	
//Afisare temperatura setata
show_current_temp:
	mov a,#8Eh 		;Pozitionare cursor pe prima linie pozitia 14
	acall instructiuni
	acall delay
	mov a,r6; punem in acc temperatura citita
	mov B,#10									
	div AB	; divide at 10 in order to get the tens from A value. Ex: 45/10 = 4 
	add A, #30h	; add 30h to get the ascii value of the tens remaining in A
	mov P2, A; mov in P2, A in order to transmit the character
	acall date
	acall delay
	mov A,B	; the remainder of the division will be saved in B so we will move in A the remainder
	add A, #30h	; get ascii character
	mov P2, A; transmit the character to LCD	
	acall date
	acall delay
ret
	
	
// Afisare temperatura actuala
show_set_temp:
	mov a,#0CEh	; Pozitionare cursor pe a doua linie pozitia 14
	acall instructiuni
	acall delay
	mov a,R0	; punem in a valoarea temperaturii de referinta
	mov b,#0ah	; punem in b 10
	div ab; facem impartirea pt a obtine zecile
	add a,#30h	; adaugam 30 pt a aobtine valoarea ascii
	acall date
	acall delay
	mov a,b	; mutam in a ceea ce ne-a ramas in b in urma impartirii
	add a,#30h	; obtinem valoareaa ascii
	acall date
	acall delay
ret

//Tastatura
temp_control:
	jnb P0.0,Buton1 ;Se verifica daca "+" este apasat
	jnb P0.1,Buton2 ;Se verifica daca "-" este apasat
	sjmp gata
	
Buton1: 
	mov r3,#255 ; call delay
debouncing_1: 
	jb P0.0,Buton1  
	djnz r3,debouncing_1
	mov a, r0; punem in a temp de referinta
	subb a, #51	; facem o verificare ca temp sa nu fie mai mare decat 51, adica val maxima pe care o pot avea in urma convertirii
	jz gata ; daca diferenta e zero, inseamna ca am citit 51 de grade si nu mai putem incrementa
	inc R0; altfel, incrementeaza valoarea de referinta
	acall show_set_temp			
	
b1:
	jnb P0.0,b1	; numai cand nu mai e apasat butonul se iese din eticheta Buton1
	sjmp gata

Buton2:
	mov r3,#255
debouncing_2:
	jb P0.1,Buton2
	djnz r3,debouncing_2
	mov a,r0
	jz gata
	dec R0
	acall show_set_temp
b2:jnb P0.1,b2
	jmp gata	
gata: ret

//Releu	
relay:
	push acc
 	 mov a,r6 ;Valoarea citita o punem in a
	 subb a,R0 ; scadem din valoarea cittia, valoarea actuala
	 jc start ; Se verifica daca temperatura setata este mai mare decat cea actuala
	 sjmp oprire
start: 
	setb P3.5 ; Pornire releu
		sjmp gata2
oprire: 	
	clr P3.5;Oprire releu
gata2: pop acc 
	ret


//Intarzierea	
delay:
	mov R7,#229	; 229 - the value which will multiply the x time delay
	repeat:
		nop	; 6 cycles -1 for each nop and 2 for djnz - => 6 * 1.085 us = 6.51us delay for one loop
		nop
		nop								
		nop
		djnz R7,repeat	; 6.51 us * 229 = 1.5 ms total delay
ret							
	
	
org 0500h
	db "Temp.setata:"
	
org  0900h
	db 'Temp.actuala', 00h
	

end
