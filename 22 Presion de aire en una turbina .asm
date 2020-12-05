/*
3-Un  sistema  basado  en  ATmega16  debe  medir  presi�n  de  aire  en  una  turbina  de  un  proceso industrial.
El  sistema  recibe  un  valor  digital  de  8  bits  equivalente  a  la  presi�n,  el  cual  ser�  medido  en intervalos de 5seg a partir de que se active un interruptor ON/OFF. Los valores medidos deben ser almacenados  en  memoria  SRAM    a  partir  de  la  direcci�n  60h,  almacenando  un  total  de  1000valores.
El sistema realizar� un control de la presi�n recibiendo una se�al de referencia proveniente de una computadora  central  que  activa  en  �1�    o  en  �0�  permitir�  seleccionar  dos  niveles  de    presi�n  de referencia almacenados previamente en ROM en las direcciones 100h y 101h respectivamente.
El control se implementar� de la siguiente forma:
-Si el valor medido de presi�n es mayor que la referencia, se debe abrir una v�lvula de salida activa en �0�, manteniendo cerrada una v�lvula de entrada de aire.
-Si el valor de presi�n es menor que la referencia se debe abrir la v�lvula de entrada y cerrar la de salida
El  proceso  se  realizar�  para  cada  muestra  de  presi�n  y  mientras  el  interruptor  est�  activado.  La selecci�n  de  la  presi�n  de  referencia  se  realizar�  s�lo  cuando  comienza  un  proceso  de  medici�n (activaci�n del interruptor).
El sistema debe permitir comenzar otro proceso de control cada vez que se active el interruptor.*/
*/
.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configuraci�n de puertos:Interruptor PA0,PB presi�n, computadora PA1, PA2 valvula salida, PA3 valvula entrada
SBI DDRA,2
SBI DDRA,3


Interruptor: ;activo en 1
	SBIS PINA,0
	RJMP Interruptor

SBIC PINA,1
CALL Computadora0
SBIS PINA,1
CALL Computadora1

LDI XL,LOW(0x60)
LDI XH,HIGH(0x60)
LDI R17,4
LecturaPresion:
	LDI R18,250
	ciclo250:
		IN R19,PINB
		ST X+,R19	
		
		CP R19,R16	;Comparar presion con la referencia
		BRSH MayorAReferencia
		BRLO MenorAReferencia
		MayorAreferencia:
			BREQ Seguir
			CBI PORTA,2
			SBI PORTA,3
			RJMP seguir
		MenorAreferencia:
			SBI PORTA,2
			CBI PORTA,3
		Seguir:
			SBIS PINA,0	;proceso siempre y cuando interruptor ON
			CALL retardo5s
			DEC R18
			BRNE ciclo250
			DEC R17
			BRNE LecturaPresion
			RJMP Interruptor


Computadora0:
	LDI ZL,LOW(0x101<<1)
	LDI ZH,HIGH(0x101<<1)
	LPM R16,Z
RET
Computadora1:
	LDI ZL,LOW(0x100<<1)
	LDI ZH,HIGH(0x100<<1)
	LPM R16,Z
RET



retardo5s:
	LDI R22,2
	ciclo3:
		LDI R23,250	
	ciclo4:
		CALL retardo10ms
		DEC R23
		BRNE ciclo4
		DEC R22
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

