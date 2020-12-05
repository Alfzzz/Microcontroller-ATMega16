/*Programa  que  debe  leer  el  puerto  C  y  
comparar  el  valor  leído  con  un  valor  de  referencia almacenado en ROM  
en la dirección 300h.  Si ambos valores coinciden se debe enviar un “0” por una  PC0  hacia  
un  sistema  de  control  durante  50ms,  de  lo  contrario  encender  un  led  de  
error conectado a PC1 durante  3segundos.*/
.ORG 0
.INCLUDE "m16def.inc"
.DEF ContadorTabla=R20
.DEF Negativos=R21

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Puerto C arranca como entrada
SBI DDRC,0	;bit de sistema de control como salida
SBI DDRC,1	;bit de led de error como salida
SBI PORTC,0	;PC0,sistema de control, en 1 como predeterminado antes de la comparación

IN R16,PINC

LDI ZL,LOW(0x300<<1)
LDI ZH,HIGH(0x300<<1)
LPM R17,Z

CP R16,R17
BREQ SistemaDeControl
SBI PORTC,1	;ocurre esto en caso de que no sean iguales
LDI R18,60
Ciclo60:	;realizamos 60 veces retardos de 50ms, 60*50ms=3s
	CALL retardo50ms
	DEC R18
	BRNE Ciclo60
CBI PORTC,1
RJMP Fin

SistemaDeControl:
	CBI	PORTC,0
	CALL retardo50ms
	SBI PORTC,0
	RJMP Fin

retardo50ms:
	LDI R22,5
	Ciclo5:
		CALL retardo10ms
		DEC R22
		BRNE Ciclo5
RET

retardo10ms:
	LDI R20,104
	ciclo104:
		LDI R21,255
	ciclo255:
		DEC R21
		BRNE ciclo255
		DEC R20
		BRNE ciclo104
RET

Fin:
	RJMP Fin