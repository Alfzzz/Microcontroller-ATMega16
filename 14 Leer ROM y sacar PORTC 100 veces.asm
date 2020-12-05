/*Programa que  lea una tabla en ROM de 100 valores a partir de la 200h  y  saque los valores por el puerto C en intervalos de 1 segundo*/

.ORG 0
.INCLUDE "m16def.inc"
;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

LDI R16,0xFF
OUT DDRC,R16

LDI ZL,LOW(0x200<<1)
LDI ZH,HIGH(0x200<<1)

LDI R16,100

Ciclo100:
	LPM R17,Z+
	OUT PORTC,R17
	CALL retardo1s
	DEC R16
	BRNE Ciclo100
	RJMP Fin

retardo1s:
	LDI R21,100
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
