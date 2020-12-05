/*1-  Diseñe  usando  un  ATMEGA  16  un  sistema  que  permita  monitorear  la  posición  de  una antena  parabólica.  El  sistema  recibe  a  través  de  un  un  canal  del  ADC  la  posición  de  la antena en un rango de 0 a 120 con una precisión de 0.1El sistema posee las siguientes teclas de comandos:

Tecla  posición:  Permitirá  leer  la  posición  de  la  antena  y  visualizarla  en  un  display  de  4 lámparas 7s indicando con un led el punto decimal. El valor leído debe compararse con un patrón almacenado en ROM a partir de la dirección 0x100.Si el valor leído es menor que el patrón debe activarse un motor de giro a la izquierda y en caso contrario un motor de giro a la derecha. La medición se repetirá hasta que coincida el valor con el patrón.

Tecla Tx: Se transmitirá por el puerto serial a 1200 baudios, el patrón almacenado en ROM , enviando primero los 8LSB  y después los 8MSB.
Considere en todo el diseño el valor de posición sin el punto decimal. (frec=8Mhz).*/

INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 2
RJMP teclaPosicion
.ORG 4
RJMP teclaTX
.ORG 1C
RJMP adc
.ORG 0x26
RJMP refresh

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	
	;Puertos
	LDI R16,0b01110010	;LED,motor Izquierda motor derecha, tx 	
	SBI PORTD,6	;Led

	;Displays7seg x4
	LDI XH,0
	LDI XL,0x60
	LDI R24,4
	LDI R25,0b11101111
	;Valores inicialies de display
	CLR R16
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	STS 0x63,R16
	
	;ADC, asumiendo Vref de 2.56
	LDI R16,0b11000000	;Vref=2.56V(1LSB=2.5mV), ajustado a la derecha,primer canal
	OUT ADMUX,R16
	LDI R16,0b10001111	;ADEN(Habilitar ADC),ADIE(Habilitar interrupción por ADC), prescaler de 128
	OUT ADCSRA,R16

	;Serial
	LDI R16,0b10000110	;Seleccionar UCSRC, asíncrono, sin paridad, 1 bit de STOP, 8 bits de dato
	OUT UCSRC,R16
	LDI R16,0b00001000	;habilitar transmisión
	OUT UCSRB,R16
	LDI R16,HIGH(415)	;1200 baudios
	OUT UBRRH,R16
	LDI R16,LOW(415)
	OUT UBRRL,R16
	
	;Interrupciones externas y de timer
	LDI R16,0b11000000	;INT1,INT0
	OUT GICR,R16
	LDI R16,0b00001010	;Detección por flanco de bajada para INT0 y INT1
	OUT MCUSR,R16
	LDI R16,0b00000010	;OCIE0, timer 2 compara para refresh 	
	OUT TIMSK,R16
	LDI R16,38	;(1/(4*50Hz))/125ns/1024-1=38
	OUT OCR0,R16
	LDI R16,0b00001101	;CTC, prescaler 1024
	OUT TCCR0,R16
	SEI 	

	CLT ;Indicador de que se leyó el valor de la posición, activo en 1
	fin:
		BRTS matchPosicion
		RJMP fin
		matchPosicion:
			CP R12,R14	;Comparar parte alta del valor leído con parte alta de valor de la ROM
			BRNE fin
			CP R11,13	;Comparar parte baja del valor leído con parte baja de valor de la ROM
			BRNE fin
			CBI PORTD,4	;Coincide valor del patrón con el valor leído, se apagan motores
			CBI PORTD,4
			CLT
			RJMP fin

teclaPosicion:
	IN R15,SREG
	PUSH R15
	
	;Rebote
	CALL retardo10ms
	SBIC PIND,2
	RJMP teclaRETI
	SEI	;dejar que entre la interrupción de refresh
	teclaMenosPolling:
		SBIS PIND,2
		RJMP teclaMenosPolling
	CALL retardo10ms	

	SBI ADCSRA,ADSC	;Empezar a convertir

	POP R15
	OUT SREG,R15
	RETI

adc:
	IN R15,SREG
	PUSH R15
	
	SET
	IN BIN_LSB,ADCL
	IN BIN_MSB,ADCH
	MOV R11,BIN_LSB
	MOV R12,BIN_MSB
	CALL BIN2BCD
	LDI ZH,HIGH(0x100<<1)
	LDI ZL,LOW(0x100<<1)	
	LPM R13,Z+	;LSB
	LPM R14,Z	;MSB
	CP R12,R14
	BRLO motorIzquierda
	BREQ compararLSB
	RJMP motorDerecha
	compararLSB:
		CP R11,R13
		BRLO motorIzquierda
		RJMP motorDerecha	

	motorIzquierda:
		SBI PORTD,4
		CBI PORTD,5
		RJMP teclaPosicionRETI
	motorDerecha:
		SBI PORTD,5
		CBI PORTD,4
		RJMP teclaPosicionRETI
		tecladoPosicionRETI:
			POP R15
			OUT SREG,R15
			RETI	
teclaTX:
	IN R15,SREG
	PUSH R15

	;Rebote
	CALL retardo10ms
	SBIC PIND,3
	RJMP teclaRETI
	SEI	;dejar que entre la interrupción de refresh
	teclaMenosPolling:
		SBIS PIND,3
		RJMP teclaMenosPolling
	CALL retardo10ms

	LDI ZH,HIGH(0x100<<1)
	LDI ZL,LOW(0x100<<1)
	LPM R16,Z+
	LPM R17,Z
	OUT UDR,R17	;Enviar
	pollingTX1:
		SBIS UCSRA,UDRE
		RJMP pollingTX1
	OUT UDR,R16
	pollinTX2:
		SBIS UCSRA,UDRE
		RJMP pollingTX2
	POP R15
	OUT SREG,R15
	RETI

refresh:
	IN R15,SREG	;Salvar el entorno
	PUSH R15
	
	LD R0,X+	;Leer RAM
	MOV R20,R25	;código de barrido a R20
	ANDI R20,0xF0	;Enmascarar código de barrido
	ADD R0,R20	;Sumar número a mostrar en parte baja
	OUT PORTB,R0	;Mostrar por el puerto
	ROL R25	;Rotar
	DEC R24	;Decrementar contador
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,4	;contador
	LDI R25,0b11101111	;código de barrido para display7seg ánodo común x4
	refreshRETI:
		POP R15
		OUT SREG,R15
		RETI
BIN2BCD: 
	CLR R16                  
	STS 0x60,R16                  
	STS 0x61,R16  
	STS 0x62,R16  	
	STS 0x63,R16    
	otro:  
		CPI BIN_LSB,0           
		BRNE INC_BCD           
		CPI BIN_MSB,0           
		BRNE INC_BCD           
		RET
	
		INC_BCD: 	
			LDI R17,0      	
			LDI YL,0x63      
			LDI YH,0     
			cicloINC_BCD: 
				LD R20,Y            
				INC R20            
				ST Y,R20            
				CPI R20,10            
				BRNE DEC_BIN           
				ST Y, R17            	
				DEC YL            
				CPI YL,0x5F            
				BRNE cicloINC_BCD
				
				DEC_BIN: 
					DEC BIN_LSB         
					CPI BIN_LSB,0xFF         
					BRNE otro         
					DEC BIN_MSB         
					RJMP otro		
retardo10ms:
	;OCR2
	LDI R16,77
	OUT OCR2,R16
	
	;Palabra de control
	LDI R16,0b00001111
	OUT TCCR2,R16
	
	Polling:
		IN R16,TIFR
		SBRS R16,OCF2
		RJMP Polling
	
	;Parar timer
	CLR R16
	OUT TCCR2,R16

	;Paggar bandera
	LDI R16,1<<OCF2
	OUT TIFR, R16
RET

.ORG 0x100
.DB 100,1