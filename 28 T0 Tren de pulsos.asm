/*
Generar  por  el  pin  de  puerto  PB0  del  ATMEGA16  un  tren  de  pulsos  que  varía  su  ancho  de acuerdo al estado de un interruptor de la siguiente forma:-Si el interruptor está en ON el pulso se genera con 20ms en “1” y 40ms en “0”-Si el interruptor está en OFF se debe generar un tren de pulsos con 30ms en “1” y 10ms en “0”.El proceso se repetirá continuamente hasta que se produzca un reset del procesador.Frecuencia del cristal=8MHz1.1  Realice el ejercicio utilizando el timer 0 en modo normal.1.2  Repita el ejercicio utilizando el timer 0 en modo CTC (Clear time o compare match)
*/
.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

SBI DDRB,0 ;Tren de pulsos

PollingInterruptor:
	SBIC PINB,1
	RJMP A
	OFF:
		SBI PORTB,0
		CALL delay30ms
		CBI PORTB,0
		CALL delay10ms
		RJMP PollingInterruptor
	ON:
		SBI PORTB,0
		CALL delay20ms
		CBI PORTB,0
		CALL delay40ms
	RJMP PollingInterruptor

delay10msNormal:
	/*TCNT0=256-T/(N*Tr)=256-10m/(1024*125ns)=178    */
	LDI R16,178	;Dónde empezar a contar
	OUT TCNT0,R16
	LDI R16,0b00000101 ;modo normal prescaler de 1024
	OUT TCCR0,R16	;Empiezar a contar timer
	Polling10msNormal:
		IN R16,TIFR
		SBRS R16,TOV0
		RJMP Polling10msNormal
	CLR R16
	OUT TCCR0,R16	;Apagar timer
	LDI R16,1<<TOV0
	OUT TIFR,R16	;Apagar bandera
RET

delay10msCTC:
	/*OCR0=T/(N*Tr)-1=10ms/(1024*125n)-1=77    */
	LDI R16,77
	OUT OCR0,R16
	LDI R16,0b00001101
	OUT TCCR0,R16
	Polling10msCTC:
		LDI R16,TIFR
		SBRS R16,OCF0
		RJMP Polling10msCTC
	CLR R16
	OUT TCCR0,R16	;Apagar Timer
	LDI R16,1<<OCF0
	OUT TIFR,R16	;Apagar Bandera
RET

delay30ms:
	LDI R17,3
	ciclo1:
		CALL delay10msNormal
		DEC R17
		BRNE ciclo1
RET

delay20ms:
	LDI R17,2
	ciclo2:
		CALL delay10msNormal
		DEC R17
		BRNE ciclo2
RET
delay40ms:
	LDI R17,4
	ciclo4:
		CALL delay10msNormal
		DEC R17
		BRNE ciclo4
RET