/*Realice un programa que permita controlar el nivel de agua en un tanque. Se disponede un sensor que entrega un “0” cuando se alcanza determinado nivel. El sistema debe abrir una válvula de escape de agua y activar una alarma sonora ( buzzer) 1segON y 1 seg OFF. La desactivación de la alarma se hará con un switch ON/OFFEl sensor y el switch se atenderán por interrupciones externas y la alarma por Interrupción de timer */

/*100*10ms=1s
cteT=10ms/(125*1024)=78
OCR0=cteT-1=78-1=77*/

.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 2
RJMP sensor
.ORG 4
RJMP switch
.ORG 0x26
RJMP alarma

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	
	;Cofiguración de puertos
	LDI R16,0b00000011	;Buzzer y valvula
	OUT DDRB,R16
	
	LDI R16,0b11000000	;Habilitar INT0 e INT1
	OUT GICR,R16
	LDI R16,0b00000010	;Hailitar OCIE0
	OUT TIMSK,R16
	LDI R16,0b00001010	;Detectar flanco de bajada para INT1(switch) y también para INT0(sensor) 
	OUT MCUCR,R16
	SEI	;Habilitar Interrupciones 
	Fin:
		RJMP Fin
;Interrupciones
Sensor:
	SBI PORTB,1	;Valvula
	SBI PORTB,0	;Buzzer
	LDI R16,77	
	OUT OCR0,R16	;Cargar 77 a 0CR0, 10ms
	LDI R16,0b00001101	;Modo CTC y prescaler de 1024
	OUT TCCR0,R16
	LDI R25,100	;Contador para el timer 100*10ms=1s
	RETI
Alarma:
	DEC R25
	BRNE AlarmaRETI
	LDI R25,100	;Volver a poner 100 en el contador
	LDI R17,0b00000001 ;Preparar registro mascara para toglear Buzzer
	IN R16,PORTB	Leer el puerto B, se usa port porque leemos lo que escribimos
	EOR R16,R17 ;Aplicar mascara para toglear Buzzer
	OUT PORTB,R16
	AlarmaRETI:
		RETI
Switch:
	CBI PORTB,0	;Cerrar valvula
	CBI PORTB,1	;Apagar Buzzer
	CLR R16
	OUT TCCR0,R16	;Apagar Timer
	RETI
