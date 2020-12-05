;Realice un programa que lea el puerto C del ATMEGA 16 y cuente las Veces que aparece dicho valor en una tabla en Flash de ;50 valores ubicadaa partir de la dirección 0x300. Al finalizar se debe guardar el valor del contadorEn la dirección 0x70 ;de SRAM y encender un led conectado a PB7.

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRB,7	;PB7 salida
LDI ZL,LOW(0x300<<1)	;Puntero Flash
LDI ZH,HIGH(0x300<<1)
LDI R16, 50	;contador de ciclos
LDI R17,0	;contador de coincidencias
IN R18,PINC	;Leer Puerto C
Ciclo:
	LPM R20,Z+	;Leer Flash
	CP R18,R20
	BRNE seguir
	INC R17
Seguir:
	DEC R16
	BRNE Ciclo
STS 0x70,R17	;Store RAM
SBI PORTB,7	;LED
FIN:
	RJMP FIN
.ORG 0x300
Tabla:
	;.DB 1,23,4,5,6,7,8,9,10.......50