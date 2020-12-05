/*Realice un programa que lea el canal 2 de ADC y muestre el resultado en los puertos B(LSB) y D(MSB)*/

.INCLUDE "m16def.inc"
.ORG 0	

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
LDI R16,0b10000111	;Habilitar ADC, prescaler select bit de 128
OUT ADCSRA,R16
SBI ADCSRA,ADSC	;Empezar a convertir

polling:
	SBIS ADCSRA,ADIF	;Esperar a que termine la conversión	
	RJMP polling

SBI ADCSRA,ADIF	;Apagar bandera

;Leer el valor convertido
IN R16,ADCL
OUT PORTB,R16
IN R16,ADCH
OUT PORTD,R16

fin:
	RJMP fin