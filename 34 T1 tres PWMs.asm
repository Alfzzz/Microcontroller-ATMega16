/*3-   Realice  un  programa  que  compare  un  valor  8bits  leído  por  el  puerto  A  con  una referencia almacenada en ROM en la dirección 0x400. La comparación se debe realizar cada 20ms.  El sistema debe generar por una línea de puerto un tren de pulsos de 20ms, la cual se variará su ciclo útil  de acuerdo al resultado de la comparación anterior. Si el valor leído es mayor a la referencia el pulso se generará con un 80% de ciclo útil, si es menor con un 30% y si es igual  con un 50%. */

/*Timer 1
F_señal=1/50ms=8MHz/((Top+1)*1024)
Top=8M*20m/1024-1=155-------->ICR1H|ICR1L Modo 14

30%Duty Cycle:Match 0CR1H|OCR1L = Tope*0.5=46
50%Duty Cycle:Match 0CR1H|OCR1L = Tope*0.5=77
80%Duty Cycle:Match 0CR1H|OCR1L = Tope*0.5=124

Palabra de control:
TCCR1A=|COM1A1|COM1A0|COM1B1|COM1B0|FOC1A|FOC1B|WGM11|WGM10|=10000010 Clear para OC1A,Modo 14 Fast PWM
TCCR1B=|ICNC1|ICES1|--|WGM13|WGM12|CS12|CS11|CS10|=00011101 Modo 14 Fast PWM, prescaler de 1024 
OC1B sale por PD4
*/


.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16


;
SBI DDRD, 5 ;salida PWM OC1A

LDI R16,HIGH(155)	;Tope
OUT ICR1H,R16
LDI R16,LOW(155)
OUT ICR1L,R16

LDI ZH,HIGH(0x400)<<1
LDI ZL,LOW(0x400)<<1
LPM R25,Z

Ciclo:
	CALL retardo20ms
	IN R24,PINA
	CP R24,R25	;Comparar valor con la referencia
	BRLO DutyCycle30
	BREQ DutyCycle50
	
	DutyCycle80:
		LDI R16,HIGH(124)	;Match 0CR1H|OCR1L = Tope*0.8=124
		OUT OCR1AH,R16
		LDI R16,LOW(124)
		OUT OCR1L,R16
		LDI R16,0b10000010	;Modo 14, , Clear para OC1A
		OUT TCCR1A,R16
		LDI R16,0b00011101	;Prescaler de 1024, modo 14
		OUT TCCRB,R16
		RJMP Ciclo 

	DutyCycle50:	
		LDI R16,HIGH(77)	;Match 0CR1H|OCR1L = Tope*0.5=77
		OUT OCR1AH,R16
		LDI R16,LOW(77)
		OUT OCR1L,R16
		LDI R16,0b10000010	;Modo 14, , Clear para OC1A
		OUT TCCR1A,R16
		LDI R16,0b00011101	;Prescaler de 1024, modo 14
		OUT TCCRB,R16
		RJMP Ciclo

	DutyCycle30:
		LDI R16,HIGH(46)	;Match 0CR1H|OCR1L = Tope*0.3=46
		OUT OCR1AH,R16
		LDI R16,LOW(46)
		OUT OCR1L,R16
		LDI R16,0b10000010	;Modo 14, Clear para OC1A
		OUT TCCR1A,R16
		LDI R16,0b00011101	;Prescaler de 1024, modo 14
		OUT TCCRB,R16		
		RJMP Ciclo


retardo20ms:
	LDI R16,155
	OUT OCR0,R16
	LDI R16,0b00001101 ;modo CTC, prescaler de 1024
	OUT TCCR0,R16
	Polling20ms:
		IN R16,TIFR
		SBRS R16,OFC0
		RJMP Polling20ms
	CLR R16
	OUT TCCR0,R16 	;Apagar Timer
	LDI R16,1<<OCF0
	OUT TIFR,R16	;Apagar Bandera
RET

;Referencia
.ORG 0x400
.DB 5