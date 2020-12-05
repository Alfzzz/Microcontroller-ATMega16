/*Usando el T1 en modo CTC generar un DELAY de  1s que permita cambiar elestado de un led conectado a PC4 cada ese tiempo. Freq=8MHZ*/
/*
cteT1=T/Tr=1s/125ns=8000000 no cabe en 16 bits 645536
cteT2=T/Tr=1ss/(8*125ns)=1000000 no cabe en 16 bits con prescaler de 8
cteT3=T/Tr=1s/(64*125ns)=125000 cabe en 16 bits prescaler de 64
cteT4=T/Tr=1s/(256*125ns)=31250 cabe en 16 bits con prescaler de 256
cargar 31250-1=31249 en OCR1AH|OCR1AL
Palabra de control 00000000|00001100 modo CTC con prescaler de 256
*/

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRC,4

ciclo:
	SBI PORTC,4
	CALL delay1s
	CBI PORTC,4
	CALL delay1s
	RJMP ciclo

delay1s:
	;OCR1AH|ORCR1AL
	LDI R16,HIGH(31249)
	OUT OCR1AH,R16
	LDI R16,LOW(31249)
	OUT OCR1AL,R16

	;Palabra de control	
	CLR R16
	OUT TCCR1A,R16
	LDI R16,0b00001100	;prescaler de 256 y modo CTC
	OUT TCCR1B,R16

	Polling:
		IN R16,TIFR
		SBRS R16,OCF1A
		RJMP Polling
	
	;Detener timer
	CLR R16
	OUT TCCR1B,R16
	
	;Apagar bandera
	LDI R16,1<<OCF1A
	OUT TIFR, R16
RET