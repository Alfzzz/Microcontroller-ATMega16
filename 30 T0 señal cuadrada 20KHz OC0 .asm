/*Ejercicio 5 Generar usando el Timer 0 una señal cuadrada de frecuencia= 20KHZ*/
/*
F_OC0=f_clk/(2N(OCR0+1))
OCR0=8M/20K/2/1-1=199 sin prescaler cabe
Palabra de control:00011001 sin prescaler, OC0 con toggle, modo CTC 
OC0 es por PB3
*/

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRB,3
LDI R16,199
OUT OCRO,R16
LDI R16,0b00011001
OUT TCCR0,R16

Fin:
	RJMP,Fin
 