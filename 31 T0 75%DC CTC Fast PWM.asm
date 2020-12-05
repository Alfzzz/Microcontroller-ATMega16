/*Ejercicio 6 Generar usando el Timer 0 una señal PWM de 31250HZ  con 75% de ciclo útil. UtiliceFAST PWM y modo no invertido.*/
/*
N=8M/31250/256=1
OCR0=0.75*256-1=191
OC0 sale por PB3
Palabra de control: TCCR0=01101001 Fast PWM,modo clear, sin prescaler 
*/

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRB,3
LDI R16,191
OUT OCR0,R16
LDI R16,0b01101001
OUT TCCR0,R16

Fin:
	RJMP,Fin




