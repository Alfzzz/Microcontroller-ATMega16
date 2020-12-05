/*Realice un programa que lea el estado de un switch conectado a PB2. 
Si el switch es “0” enviar el carácter ‘N’ por el puerto C y
 encender un led conectado a PB0 durante 3 segundos. 
 Si el switch es  “1  enviar  el  carácter  ‘Y’  por  el  puerto  C  y  
 enviar  una  señal  activo  en  “0”  por  PB1  durante 100ms.
 El programa debe permanecer leyendo el switch continuamente.*/

 .ORG 0
.INCLUDE "m16def.inc"
.DEF ContadorTabla=R20
.DEF Negativos=R21

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;PB2 arranca modo entrada
LDI R16,0xFF
OUT DDRC,R16
SBI DDRB,0
SBI DDRB,1
SBI PORTB,1	;Activo en 0

LeerSwitch:
	SBIC PINB,2
	RJMP SwitchEn1
LDI R16,'N'
OUT PORTC,R16
SBI PORTB,0	;Encender LED
;llamar 30 veces retardos de 100ms, 30*100ms=3s
LDI R16,30
ciclo30:
	CALL retardo100ms
	DEC R16
	BRNE ciclo30
CBI PORTB,0	;Apagar LED después de 3s
RJMP LeerSwitch

SwitchEn1:
	LDI R16,'Y'
	OUT PORTC,R16
    CBI PORTB,1	;Enviar "0" a PB1
	CALL retardo100ms
	SBI PORTB,1	;Regresar a "1" después de 100ms
	RJMP LeerSwitch


retardo100ms:
	LDI R22,10	
	ciclo10:
		CALL retardo10ms
		DEC R22
		BRNE ciclo10
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


