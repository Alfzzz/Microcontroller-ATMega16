/*
Realice  un  programa  que  cuente  la  cantidad  de  valores  positivos  y  negativos  de  una  lista  de  
15 elementos almacenada en SRAM a partir de la dirección 100h.
 Si la cantidad de valores positivos es mayor o igual que la de negativos se debe prender un led conectado al puerto PB0, 
 de lo contrario, encender un led en el puerto PB7.  
*/

.ORG 0
.INCLUDE "m16def.inc"
.DEF ContadorTabla=R20
.DEF Negativos=R21

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRB,0	;poner bit 0 del puerto B en 1
SBI DDRB,7	;poner bit 7 del puerto B en 1

;Puntero X
LDI XL,LOW(0x100)
LDI XH,HIGH(0x100)

LDI ContadorTabla,15
LDI R16,-8

;Ciclo para llenar tabla
LlenarTabla:
	ST X+,R16
	INC R16
	DEC ContadorTabla
	BRNE LlenarTabla

;Reiniciar puntero
LDI XL,LOW(0x100)
LDI XH,HIGH(0x100)
LDI ContadorTabla,15
CLR Negativos

;Ciclo para leer RAM
ContarNegativos:
	LD R16,X+
	CPI R16,0	;R16-0
	BRGE Continuar
	INC Negativos

Continuar:
	DEC ContadorTabla
	BRNE ContarNegativos

CPI Negativos,8	 ;Se compara si hay más negativos o positivos
BRLO LEDPB0
SBI PORTB,7		;Encender si hay más positivos
RJMP Fin

LEDPB0:
	SBI PORTB,0	 ;Encender si hay más negativos, en este caso se enciende porque hay más negativos que positivos

Fin:
	RJMP Fin