;Realice un programa que compare un valor leído por el Puerto A con otro almacenado en SRAM en la dirección 0x60. Si el primer valor es mayor que el 2do encender un ledconectado a PB0, si es menor encender un led conectado a PB1, si ambos valores coinciden sacar dicho valor por el Puerto C. 

.ORG 0
.INCLUDE "m16def.inc"
.def valor=R16
.def RAM=R17

LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SER R16
OUT DDRC,R16
SBI DDRC,0
SBI DDRC,1
IN valor,PORTC
LDS RAM,0x60

CP R16,R17
BRLO menor
BREQ igual

SBI PORTB,0
RJMP FIN

menor:
	SBI PORTB,1
	RJMP FIN
igual:
	OUT PORTC,R16
FIN:
	RJMP FIN