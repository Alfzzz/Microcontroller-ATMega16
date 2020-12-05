;Escribir el valor de 0xFF en las primeras 50 direcciones de la SRAM a partir de la 0x60

.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

LDI XL,LOW(0x60)
LDI XH, HIGH(0x60)
LDI R16,50
LDI R17,0xFF
FOR:
	ST X+,R17
	DEC R16
	BRNE FOR
