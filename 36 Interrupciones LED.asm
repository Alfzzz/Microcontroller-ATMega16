/*1-Se  tienen  dos  switches  S1  y  S2  conectados  a  los  pines  de  interrupción  externa  INT0  e  INT1. Realice un programa que si se activa el S1 se incremente en 1 el valor del puerto C y si se activa el S2  se  decremente  en  1.  Si  el  valor  del  puerto  está  entre  10  y  100  encender  un  led  conectado  a PB7, de lo contario mantenerlo apagado.*/

.ORG 0x0	;Reset
RJMP main
.0RG 0x2	;INT0
RJMP sw1
.ORG 0x4	;INT1
RJMP sw2

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	
	SBI DDRB,7

	;Interrupciones
	LDI R16,0b11000000	;Habilitar INT0(SW1),INT1(SW2)
	OUT GICR,R16  		
	LDI R16,0b00001010	;Detectar flanco de bajada para INT0 e INT1
	OUT MCUCR,R16
	SEI
	fin: 
		RJMP fin

sw1:
	IN R17,SREG
	PUSH R17

	IN R16,PORTC
	INC R16
	OUT PORTC,R16	
	RJMP LED
sw2:
	IN R17,SREG
	PUSH R17

	IN R16,PORTC
	DEC R16
	OUT PORTC,R16
	RJMP LED
LED:
	CPI R16,10
	BRLO apagarLED
	CPI R16,101
	BRSH apagarLED
	SBI PORTB,7
	RJMP LEDRETI
	apagarLED:
		CBI PORTB,7
	LEDRETI:
		POP R17
		OUT SREG,R17
		RETI