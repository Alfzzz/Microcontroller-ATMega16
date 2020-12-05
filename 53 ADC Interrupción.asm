/*Realice un programa que lea el canal 2 de ADC y muestre el resultado en los puertos B(LSB) y D(MSB)*/

.INCLUDE "m16def.inc"
.ORG 0	
RJMP main
.ORG 0x1C
RJMP adc

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16

	;Puertos
	SER R16
	OUT DDRB,R16
	OUT DDRD,R16

	;ADC
	LDI R16,0b11000010	;Vref=2.56V--->1LSB=2.5mV,canal 2 single ended
	OUT ADMUX,R16
	LDI R16,0b10001111	;Habilitar ADC, ADC por interrupción, prescaler select bit de 128
	OUT ADCSRA,R16
	
	SBI ADCSRA,ADSC	;Empezar a convertir

	fin:
		RJMP fin
adc:
	IN SREG,R15
	PUSH R15
	;Leer el valor convertido
	IN R16,ADCL
	OUT PORTB,R16
	IN R16,ADCH
	OUT PORTD,R16

	POP R15
	OUT SREG,R15
	RETI