;Eliminador de rebote con 10ms
.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

Polling:
	SBIC PINB,0
	RJMP Polling
CALL retardo10ms
SBIC PINB,0
RJMP Polling	;Tomar valor para ver si fue ruido
Wait:
	SBIS PINB,0
	RJMP Wait	;Esperar a que se suelte
CALL retardo10ms

;Código que tenga que hacer después del botón


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