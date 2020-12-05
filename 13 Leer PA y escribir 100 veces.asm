/*
Programa que lea el puerto A del ATmega16, 100 veces  cada 200ms y los valores los guarde en SRAM  a partir de la dirección 300h. 
*/

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

LDI XL,LOW(0x300)
LDI XH,HIGH(0x300)
LDI R16,100

Ciclo100:
	IN R17,PINA
	ST X+,R17
	CALL retardo200ms
	DEC R16
	BRNE Ciclo100
RJMP Fin

retardo200ms:
	LDI R21,20
	ciclo3:	
	CALL retardo10ms
	DEC R21
	BRNE ciclo3
RET

retardo10ms:
	LDI R20,104
	ciclo2:
		LDI R21,255
	ciclo1:
		DEC R21
		BRNE ciclo1
		DEC R20
		BRNE ciclo2
RET

Fin:
	RJMP Fin