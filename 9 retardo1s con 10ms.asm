.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

LDI R22,10
ciclo100:
	CALL retardo10ms
	DEC R22
	BRNE ciclo100
	;RET, se pone si se llama como subrutina

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
;se puede llamar retardo1s y solo al final se tendría agregar RET en la subrutina