/*1-  Realice   un   programa   que   atienda   4   canales   de   entrada   analógicos   del ATMEGA16,  la  selección  del  canal  a  leer  se  hará  por  2  interruptores  ON/FF conectados a líneas de puertos. Las entradas analógicas estarán entre 0 y 5vUna  vez  seleccionado  un  canal  el  sistema  realizará  lecturas  del  mismo  cada 100ms y las visualizará en un display 7 segmentos de 4 dígitos y encenderá uno de 4 leds correspondiente a cada canal. Las mediciones se realizarán hasta que se cambie el canal con los interruptores.*/

.INCLUDE "m16def.inc"
.DEF BIN_LSB=R21
.DEF BIN_MSB=R22

.ORG 0x00
RJMP main
.ORG 0x02
RJMP switch
.ORG 0x04
RJMP switch
.ORG 0x1C
RJMP adc
.ORG 0x26
RJMP refresh	;Refresh y conversión ADC

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	
	;Puertos
	SER R16
	OUT DDRB,R16	;refresh
	LDI R16,0xF0
	OUT DDRD,R16 	;Leds

	;refresh
	LDI XH,0
	LDI XL,0x60	;Puntero a RAM de displays7seg x4
	LDI R24,4	;Contador de displays
	LDI R25,0b11101111	;Código de barrido para ánodo común

	;Valores iniciales de los displays
	LDI R16,0
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	STS 0x63,R16

	;iInterrupciones y timer0
	LDI R16,0b00000010	;OCIE0
	OUT TIMSK,R16
	LDI R16,38	;(1/(4*50Hz))/125ns/1024-1=38
	OUT OCR0,R16
	LDI R16,0b00001101	;CTC,prescaler 1024
	OUT TCCR0,R16
	LDI R16,0b11000000	;INT1,INT0 
	OUT GICR,R16
	LDI R16,0b00000101	;Cambio de nivel para INT1 y INT0
	OUT MCUSR,R16
	SEI

	;Registro útiles
	LDI R23,20	;Contador para lectura adc cada 100ms=20*5ms
	
	fin:
		RJMP fin

switch:
	IN R15,SREG
	PUSH R15
	
	SBIC PIND,2
	RJMP canales2o3
	SBIC PIND,3
	RJMP canal1
	
	canal0:
		SBI PORTD,4
		CBI PORTD,5
		CBI PORTD,6
		CBI PORTD,7
		LDI R16,0b01000000	;AVCC(0-5V) como voltaje de referencia, justificación a la derecha, canal 0
		OUT ADMUX,R16
		RJMP convertirADC
	canal1:
		CBI PORTD,4
		SBI PORTD,5
		CBI PORTD,6
		CBI PORTD,7
		LDI R16,0b01000001	;AVCC(0-5V) como voltaje de referencia, justificación a la derecha, canal 1
		OUT ADMUX,R16
		RJMP convertirADC
	canales2o3:
		SBIC PIND,3
		RJMP canal3
		canal2:
			CBI PORTD,4
			CBI PORTD,5
			SBI PORTD,6
			CBI PORTD,7
			LDI R16,0b01000010	;AVCC(0-5V) como voltaje de referencia, justificación a la derecha, canal 2
			OUT ADMUX,R16
			RJMP convertirADC
		canal3:
			CBI PORTD,4
			CBI PORTD,5
			CBI PORTD,6
			SBI PORTD,7
			LDI R16,0b01000011	;AVCC(0-5V) como voltaje de referencia, justificación a la derecha, canal 3
			OUT ADMUX,R16
			RJMP convertirADC
	convertirADC:
		SET	;bandera para indicar que hubo cambio en el switch
		LDI R16,0b10001111	;ADEN(Habilitar ADC),ADIE(interupción de ADC),prescaler de 128	
		OUT ADCSRA,R16
		OUT SREG,R15
		POP R15
		RETI

adc:
	IN R15,SREG
	PUSH R15
	IN BIN_LSB,ADCL
	IN BIN_MSB,ADCH
	CALL  BIN2BCD	;Actualizar displays
	POP R15
	OUT SREG,R15
	RETI

refresh:
	IN R15,SREG	;Salvar el entorno
	PUSH R15
	
	BRTC refrescar	;Checar si hubo cambio en switches
	DEC R23
	BRNE refrescar	;Checar si ya pasaron 100ms
	LDI R23,20
	SBI ADCSRA,ADSC ;Empezar conversión
	refrescar:
		LD R0,X+	;Leer RAM
		MOV R19,R25	;código de barrido a R20
		ANDI R19,0xF0	;Enmascarar código de barrido
		ADD R0,R19	;Sumar número a mostrar en parte baja
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