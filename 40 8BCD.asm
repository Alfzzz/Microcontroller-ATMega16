/*Refrescamiento de display 7 segmetnos Cátodo común
*/

.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 0x26	;Timer 0 compare
RJMP refresh
	
main:
	;Pila
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16

	SER R16
	OUT DDRB,R16	;Puerto B como salida
	LDI R16,0b00000010
	OUT TIMSK,R16	;Habilitar OCIE0, interupcción timer0 compare
	LDI R16,19	;(1/(8*50Hz))/125ns/1024-1=19
	OUT OCR0,R16	
	LDI R16,0b00001101 ;Modo CTC, prescaler de 1024
	OUT TCCR0,R16

	;preparar RFSH
	LDI XL,LOW(0x60)	;puntero a RAM del display
	LDI XH,HIGH(0x60)	
	LDI R24,8	;Contador
	LDI R25,0	;Código de barrido


	LDI R16,1
	STS 0x60,R16
	LDI R16,2
	STS 0x61,R16
	LDI R16,3
	STS 0x62,R16
	LDI R16,4
	STS 0x63,R16
	LDI R16,5
	STS 0x64,R16
	LDI R16,6
	STS 0x65,R16
	LDI R16,7
	STS 0x66,R16
	LDI R16,8
	STS 0x67,R16
	SEI
	
	fin:
		RJMP fin
refresh:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
	LD R0,X+	;Leer RAM
	SWAP R25
	ADD R0,R25	;Sumar número a mostrar en parte baja
	OUT PORTB,R0	;Mostrar por el puerto
	INC R25
	DEC R24	;Decrementar contador
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,8	;contador
	;LDI R25,0b11101111	;código de barrido
	LDI R25,0
	refreshRETI:
		POP R20
		OUT SREG,R20
		RETI