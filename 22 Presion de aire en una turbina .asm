/*
3-Un  sistema  basado  en  ATmega16  debe  medir  presión  de  aire  en  una  turbina  de  un  proceso industrial.
El  sistema  recibe  un  valor  digital  de  8  bits  equivalente  a  la  presión,  el  cual  será  medido  en intervalos de 5seg a partir de que se active un interruptor ON/OFF. Los valores medidos deben ser almacenados  en  memoria  SRAM    a  partir  de  la  dirección  60h,  almacenando  un  total  de  1000valores.
El sistema realizará un control de la presión recibiendo una señal de referencia proveniente de una computadora  central  que  activa  en  “1”    o  en  “0”  permitirá  seleccionar  dos  niveles  de    presión  de referencia almacenados previamente en ROM en las direcciones 100h y 101h respectivamente.
El control se implementará de la siguiente forma:
-Si el valor medido de presión es mayor que la referencia, se debe abrir una válvula de salida activa en “0”, manteniendo cerrada una válvula de entrada de aire.
-Si el valor de presión es menor que la referencia se debe abrir la válvula de entrada y cerrar la de salida
El  proceso  se  realizará  para  cada  muestra  de  presión  y  mientras  el  interruptor  esté  activado.  La selección  de  la  presión  de  referencia  se  realizará  sólo  cuando  comienza  un  proceso  de  medición (activación del interruptor).
El sistema debe permitir comenzar otro proceso de control cada vez que se active el interruptor.*/
*/
.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configuración de puertos:Interruptor PA0,PB presión, computadora PA1, PA2 valvula salida, PA3 valvula entrada
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

