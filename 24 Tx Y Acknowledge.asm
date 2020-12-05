/*4-  Un  sistema  basado  en  ATMega16  debe  controlar  un  proceso  industrial  basado  en  patrones  de voz.  Se  dispone  de  un  patr�n  de  voz  previamente  almacenado  en  ROM  a  partir  de  la  direcci�n 1000h compuesto de 2000 muestras.
El  sistema  dispone  de  una  tecla  de  comando  Tx,  que  al  oprimirse  debe  permitir  el  env�o  por  un puerto de 8 bits de todas las muestras del patr�n anterior en intervalos de 500ms cada una. 
El sistema debe esperar una se�al de validaci�n activa en �0� proveniente del equipo de recepci�n. Si en los 2 segundos siguientes al env�o del patr�n no se ha recibido la se�al de validaci�n se debe volver a enviar el patr�n con la siguiente estructura de trama
    01111110       2000 muestras      10000001
El  proceso  podr�  repetirse  hasta  un  m�ximo  de  3  veces,  tiempo  en  el  cual  se  encender�  un  led  de error para indicar que la transmisi�n ha fallado. 
Si por el contrario la se�al de validaci�n se recibi� correctamente se debe accionar un mecanismo  activo en �0�, que permitir� la apertura de una v�lvula de escape de alto consumo de corriente.
El sistema debe quedar siempre listo para una nueva opresi�n de la tecla Tx.*/

.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configuraci�n de puertos: PB salida de puertos, PA0 Tx,  PA1 se�al de validaci�n, PA2 LED, PA3 valvula
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
Validaci�n:
	LDI R17,200
	PollingSe�alValiaci�n:
		SBIS PINA,1	;Checar si la se�al de validaci�n est� activo
		RJMP ValvulaEscape
		CALL retardo10ms
		DEC R17
		BRNE PollinSe�alValidaci�n
	LDI R17, 0b01111110
	OUT PORTB, R17
	LDI R17, 0b10000001
	OUT PORTB,R17
	DEC R16
	BRNE Validaci�n

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