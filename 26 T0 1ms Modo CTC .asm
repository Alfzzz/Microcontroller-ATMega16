/*sando el T0 en modo CTC generar un DELAY de 1ms que permita cambiar elestado del pin PB5 cada ese tiempo. Freq=8MHZ*/
/*
cteT1=T/Tr=1ms/125ns=8000 no cabe en 8 bits
cteT2=T/Tr=1ms/(8*125ns)=1000 no cabe en 8 bits con prescaler de 8
cteT3=T/Tr=1ms/(64*125ns)=125 cabe en 8 bits prescaler de 64
cargar 125-1=124 en OCR0
Palabra de control 00001011 modo ctc con prescaler
*/

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRB,5

ciclo:
	SBI PORTB,5
	CALL delay1ms
	CBI PORTB,5
	CALL delay1ms
	RJMP ciclo

delay1ms:
	;OCR0
	LDI R16,124
	OUT OCR0,R16
	
	;Palabra de control
	LDI R16,0b00001011
	OUT TCCR0,R16
	
	Polling:
		IN R16,TIFR
		SBRS R16,OCF0
		RJMP Polling
	
	;Parar timer
	CLR R16
	OUT TCCR0,R16

	;Paggar bandera
	LDI R16,1<<OCF0
	OUT TIFR, R16
RET