/*4-  Un  sistema  basado  en  ATMega16  debe  controlar  un  proceso  industrial  basado  en  patrones  de voz.  Se  dispone  de  un  patrón  de  voz  previamente  almacenado  en  ROM  a  partir  de  la  dirección 1000h compuesto de 2000 muestras.
El  sistema  dispone  de  una  tecla  de  comando  Tx,  que  al  oprimirse  debe  permitir  el  envío  por  un puerto de 8 bits de todas las muestras del patrón anterior en intervalos de 500ms cada una. 
El sistema debe esperar una señal de validación activa en “0” proveniente del equipo de recepción. Si en los 2 segundos siguientes al envío del patrón no se ha recibido la señal de validación se debe volver a enviar el patrón con la siguiente estructura de trama
    01111110       2000 muestras      10000001
El  proceso  podrá  repetirse  hasta  un  máximo  de  3  veces,  tiempo  en  el  cual  se  encenderá  un  led  de error para indicar que la transmisión ha fallado. 
Si por el contrario la señal de validación se recibió correctamente se debe accionar un mecanismo  activo en “0”, que permitirá la apertura de una válvula de escape de alto consumo de corriente.
El sistema debe quedar siempre listo para una nueva opresión de la tecla Tx.*/

.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configuración de puertos: PB salida de puertos, PA0 Tx,  PA1 señal de validación, PA2 LED, PA3 valvula
SER R16
OUT DDRB,R16
LDI R16,0b00001100
OUT DDRA, R16

;valores iniciales del led y de la valvula
CBI PORTA,2
SBI PORTA,3

;Eliminador de rebote
PollingTx:
	SBIC PINA,0
	RJMP PollingTx
CALL retardo10ms
SBIC PINA,0
RJMP PollingTx	;Tomar valor para ver si fue ruido
WaitInicio:
	SBIS PINA,0
	RJMP WaitInicio	;Esperar a que se suelte
CALL retardo10ms
;Termina el eliminador de rebote
CALL Lecura2000muestras
LDI R16,3	;intentos
Validación:
	LDI R17,200
	PollingSeñalValiación:
		SBIS PINA,1	;Checar si la señal de validación está activo
		RJMP ValvulaEscape
		CALL retardo10ms
		DEC R17
		BRNE PollinSeñalValidación
	LDI R17, 0b01111110
	OUT PORTB, R17
	LDI R17, 0b10000001
	OUT PORTB,R17
	DEC R16
	BRNE Validación

SBI PORTA,2
RJMP PollingTx

ValvulaEscape:
	CBI PORTA,3	;Nunca se apaga una vez que se enciene
	RJMP PollingTx

Lectura2000muestras:
	LDI ZH,HIGH(0x1000<<1)
	LDI ZL,LOW(0x1000<<1)
	LDI R16, 8
	ciclo8:
		LDI R17,250
		ciclo250:
			LPM R18,Z+
			OUT PORTB,R16
			CALL retardo500ms
			DEC R17
			BRNE ciclo250
			DEC R16,8
			BRNE ciclo8 
RET

retardo500ms:
	LDI R22,50
	ciclo3:
		CALL retardo10ms
		DEC R22
		BRNE ciclo3
RET
retardo2s:
	LDI R23,200
	ciclo4:
		CALL retardo10ms
		DEC R23
		BRNE ciclo4
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