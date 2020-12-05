/*Generar usando el Timer 0 del ATMEGA 16 un retardo de 10us*/
/*
cteT=T/Tr=10us/125ns=80 está bien porque cabe en 8 bits
TCNT0=256-80=176
Palabra de control TCCR0=00000001
*/
.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

LDI R16, 176
OUT TCNT0,R16	;Dónde empezar a contar
LDI R16,0b00000001
OUT TCCR0,R16	;clk normal, modo normal

Polling:
	IN R16,TIFR
	SBRS R16,TOV0	;Esperar a que la bandera T0V0 de overflow sea 1
	RJMP Polling
CLR R16
OUT TCCR0,R16 ;Parar el timer
LDI R16, 1<<TOV0
OUT TIFR,R16	;Apagar bandera T0V0 con 1

;Resto del código