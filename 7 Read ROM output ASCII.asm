;Realice un programa que lea un valor por el puerto C entre 0 y 7 y de acuerdo al valor leído obtenga en una tabla en ;Flash a partir de la 0x200 el ASCII del valor leído, al finalizar sacar dicho valor por el puerto D y encender un led ;conectado a PB4

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SER R16
OUT DDRD,R16
SBI DDRB,4

IN R16,PORTC

LDI ZL,LOW(0x200<<1)
LDI ZH,HIGH(0x200<<1)
ADD ZL,R16    ;Sumar con la entrada del puerto C para obtener el valor correcto del ASCII
LPM R17,Z

OUT PORTD,R17
SBI PORTB,4

FIN:
	RJMP FIN

.ORG 0x200
.DB '0','1','2','3','4','5','6','7'