/*Realice un programa que cuente la cantidad de personas que entran a una sala deEspectáculos. Se dispone de un sensor que entrega un pulso por cada persona que entre. Cuando hayan entrado 100 personas activar un buzzer conectado a PC4( 1seg ON y 1seg OFF)*/
/*
Timer0 como contador de pulsos externos
Timer1 delay 1s
Modo CTC, OCR0=99
Sensor de entrada entra por T0(PB0) 
Buzer PC4
Palabra de control TCCR0=FOC0|WGM00|COM01|COM00|WGM01|CS02|CS01|CS00=00001110 
*/
.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRC,4	;Buzzer
LDI R16,99
OUT OCR0, R16
LDI R16,0b00001110
OUT TCCR0,R16

Polling:
	IN R16,TIFR
	SBRS R16,OCF0
	RJMP Polling
CLR R16
OUT TCCR0,R16
LDI R16,1<<OCF0
OUT TIFR,R16

SBI PORTC,4
CALL delay1s
CBI PORTC,4

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