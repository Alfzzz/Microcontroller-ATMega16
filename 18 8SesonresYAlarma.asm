/*Un sistema con ATMEGA16 debe atender por el puerto A el estado de 8 sensores digitales de movimiento. El sistema se activa con un interruptor ON/OFF. La activaciónde un sensor debe encender una alarma sonora y visualizar en un display 7 segmentos el número del sensor activo ( valor entre 1 y 8). La desactivación del sistema se harácon el mismo interruptor ON/OFF.Nota: Considere que no se activa más de un sensor a la vez*/
.ORG 0
.INCLUDE "m16def.inc"
.DEF CONT=R20
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
	LDI CONT,1
	IN R17,PINA
	SeguirRotando:
		ROR R17
		BRCC Carry0
		INC CONT
		CPI CONT,9
		BRNE SeguirRotando
	RJMP Inicio

Carry0:
	SBI PORTB,1
	OUT PORTC,CONT
	EstadoSwitch:
		SBIS PINA,0
		RJMP EstadoSwitch
		CBI PORTB,1
		RJMP Inicio