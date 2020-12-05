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
	LDI R16,38	;(1/(4*50Hz))/125ns/1024-1=38
	OUT OCR0,R16	
	LDI R16,0b00001101 ;Modo CTC, prescaler de 1024
	OUT TCCR0,R16

	;preparar RFSH
	LDI XL,LOW(0x60)	;puntero a RAM del display
	LDI XH,HIGH(0x60)	
	LDI R24,4	;Contador
	LDI R25,0b00010000	;código de barrido para display7seg ánodo común x4

	LDI R16,0
	STS 0x60,R16
	LDI R16,2
	STS 0x61,R16
	LDI R16,4
	STS 0x62,R16
	LDI R16,6
	STS 0x63,R16
	SEI
	
	fin:
		RJMP fin
refresh:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
	LD R0,X+	;Leer RAM
	MOV R20,R25	;código de barrido a R20
	ANDI R20,0xF0	;Enmascarar código de barrido
	ADD R0,R20	;Sumar número a mostrar en parte baja
	OUT PORTB,R0	;Mostrar por el puerto
	ROL R25	;Rotar
	DEC R24	;Decrementar contador
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,4	;contador
	LDI R25,0b00010000	;código de barrido
	refreshRETI:
		POP R20
		OUT SREG,R20
		RETI