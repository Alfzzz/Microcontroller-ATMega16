/*Un sistema con ATMEGA16 debe atender por el puerto A el estado de 8 sensores digitales de movimiento. El sistema se 
activa con un interruptor ON/OFF. La activaciónde un sensor debe encender una alarma sonora y visualizar en un display 7 
segmentos el número del sensor activo ( valor entre 1 y 8). La desactivación del sistema se harácon el mismo interruptor 
ON/OFF.Nota: Considere que no se activa más de un sensor a la vez*/
.ORG 0
.INCLUDE "m16def.inc"
.DEF CONT=R19
;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SER R16
OUT DDRC,R16
SBI DDRB,1

Inicio:
CLR R16
OUT PORTC,R16

Polling:
	SBIC PINB,0
	RJMP Polling
	InicioLectura:
		LDI CONT,1
		IN R17,PINA
		
	SeguirRotando:
		ROR R17
		BRCC Carry0
		INC CONT
		CPI CONT,9
		BRNE SeguirRotando
	BRTS InicioLectura 
	RJMP Polling

Carry0:
	SET
	SBI PORTB,1
	OUT PORTC,CONT
	LDI R16,50
	ciclo50:
		CALL retardo10ms
		DEC R16
		BRNE ciclo50
	EstadoSwitch:
		INC CONT
		CPI CONT,9
		BREQ InicioLectura
		SBIS PINB,0
		RJMP SeguirRotando
		CBI PORTB,1
		RJMP Inicio

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