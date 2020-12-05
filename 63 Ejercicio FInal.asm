/*Un  sistema  basado  en  ATMEGA16  debe  medir  temperatura  en  un  recipiente  en  un  equipo  de laboratorio  en  un  rango  de  0  a  100oC  con  precisión  de  0.1oC.  El  valor  de  temperatura  será procesado  por  un  canal  del  ADC.  Se  dispone  de  un  sensor  de  temperatura  que  entrega 2.5mv/0.1oC

El  usuario  podrá  establecer  una  temperatura  de  referencia  usando  un  teclado  matricial  con  los dígitos del 0 al 9 y las siguientes teclas de comandos:

1- Comando SET POINT: Permite entrar por teclado la temperatura de referencia con la siguiente secuencia: SP        DIGITOS          ENTER.
El valor introducido por teclado debe visualizarse en un display 7s ánodo común.

2- Comando Medición: Permite iniciar la medición de temperatura en intervalos de 50ms. El valor de temperatura medido se debe visualizar en el display anterior. No se podrá realizar la medición de temperatura si no se ha entrado la referencia.

El   sistema   realizará   un   control   ON/OFF   de   la   temperatura   mediante   una   resistencia   de calentamiento.  Si  la  temperatura  medida  es  menor  que  la  referencia  se  debe  conectar  la resistencia y si es mayor o igual desconectarla.

El sistema podrá recibir adicionalmente por puerto serial los siguientes comandos:
-Comando 0x00: Se solicita al sistema que se transmita por el puerto serial el último valor de temperatura medido. (Byte LSB primero)
-Comando 0xFF: Se solicita al sistema que detenga la medición de temperatura.
La comunicación serial se hará en un formato de 8 bits a 9600 baudios.*/

.DEF CONT=R17
.DEF contTX=R18
.DEF BIN_LSB=R20
.DEF BIN_MSB=R21
.DEF tempRef_LSB=R22
.DEF tempRef_MSB=R23
.DEF tempReal_LSB=R28
.DEF tempReal_MSB=R29

.ORG 0
RJMP main
.ORG 0x16
RJMP rx
.ORG 0x18
RJMP tx
.ORG 0x26
RJMP refreshYadc

main:	
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16

	;Puertos
	SER R16
	OUT DDRB,R16	;Displays
	SBI DDRD,2	;resistencia
	SBI DDRD,1	;TX
	LDI R16,0x0F    
	OUT DDRC,R16         ; PC0-PC3 (salidas)PC4-PC7 (entradas)    

	;serial
	LDI R16,0b10000110	;seleccionar UCSRC,asíncrono,sin paridad,1bit de parada,8bits
	OUT UCSRC,R16
	LDI R16,0b10011000	;Interrupción por recpeción, habilitar rx,habilitar tx
	OUT UCSRB,R16
	LDI R16,0
	OUT UBRRH,R16	;9600 baudios
	LDI R16,51
	OUT UBRRL,R16

	;adc
	LDI R16,0b11000000	;2.56V de referencia,canal 0
	OUT ADMUX,R16
	LDI R16,0b10000111	;habilitar adc, prescaler de 128
	OUT ADCSRA,R16

	ldi cont,10	;contador 10*5ms=50ms
	
	;Configuración y preparación display ánodo común x4
	LDI XH,HIGH(0x60)	;puntero a RAM de displays
	LDI XL,LOW(0x60)
	LDI R24,4	;contador de displays
	LDI R25,0b11101111	;Código de barrido ándo común para 4

	;interrupción de timer
	LDI R16,0b00000010	;OCIE0
	OUT TIMSK,R16
	LDI R16,38	;(1/(4*50Hz))/125ns/1024-1=38	
	OUT OCR0,R16
	LDI R16,0b00001101	;CTC,prescaler 1024
	OUT TCCR0,R16
	SEI

	limpiarDisplay:
		CLR R16
		STS 0x60,R16
		STS 0x61,R16
		STS 0x62,R16
		STS 0x63,R16

	setPoint:
		call teclado
		CPI R19,10
		BRNE setPoint
	digito:
		CALL teclado
		CPI R19,10	;checar si fue díito
		BRLO rotarDisplay
		CPI R19,11	;checar si fue enter
		BRNE digito
		RJMP continuar
		rotarDisplay:
			LDS R16,0x61
			STS 0x60,R16
			LDS R16,0x62
			STS 0x61,R16
			LDS R16,0x63
			STS 0x62,R16
			STS 0x63,R19
			RJMP digito
		continuar:
			CALL BCD2BIN	
			CPI BIN_MSB,HIGH(1000) ;comparar con 1000, ya que 100.0 °C es el máximo
			BRLO datoCorrecto
			BREQ compararLSB
			RJMP limpiarDisplay	;dato equivocado, limpiar para indicar al usuario
			
			compararLSB:
				CPI BIN_LSB,LOW(1000)
				BRLO datoCorrecto
				BREQ datoCorrecto
				RJMP limpiarDisplay
				
				datoCorrecto:
					MOV tempRef_LSB,BIN_LSB
					MOV tempRef_MSB,BIN_MSB
					medicion:
						CALL teclado
						CPI R19,12
						BRNE medicion
						SET	;bandera de medicon
						RJMP setPoint
rx:
	IN R15,SREG	;salvar entorno
	PUSH R15
	IN R16,UDR
	CPI R16,0
	BREQ habilitarTX
	CPI R17,0xFF
	BREQ apagarM
	RJMP rxRETI
	
	habilitarTX:
		LDI contTX,2	;para dos datos MSB y LSB
		SBI UCSRB,UDRIE	;habilitar tx
		RJMP rxRETI
	apagarM:
		POP R15
		OUT SREG,R15
		CLT	;apagar bandera de medición
		RETI
	rxRETI:
		POP R15
		OUT SREG,R15
		RETI
	
tx:
	IN R15,SREG
	PUSH R15
	
	DEC contTX
	BRNE transmitirLSB
	OUT UDR,tempReal_MSB
	CBI UCSRB,UDRIE
	RJMP txRETI
	
	transmitirLSB:
		OUT UDR,tempReal_LSB
	txRETI:
		POP R15
		OUT SREG,R15
		RETI
	
refreshYadc:
	IN R15,SREG
	CALL refresh
	BRTC refreshYadcRETI ;salir si está apagado bandera de medición
	DEC cont	;decrementar contador de 10 hasta que pasen 50ms
	BRNE refreshYadcRETI
	LDI cont,10	;ya pasaron 50ms
	SBI ADCSRA,ADSC ;iniciar conversión
	pollingConversion:
		SBIS ADCSRA,ADIF	;esperar fin de conversión
		RJMP pollingConversion
	SBI ADCSRA,ADIF	;apagar bandera de fin de comnversión
	IN tempReal_LSB,ADCL
	IN tempReal_MSB,ADCH
	MOV BIN_LSB,tempReal_LSB
	MOV BIN_MSB,tempReal_MSB
	CALL BIN2BCD	;para mostrar en los displays
	CP tempReal_MSB,tempRef_MSB
	BRLO conectarResistencia
	BREQ compararTemperaturaLSB	
	desconectarResistencia:	;caso en el que es mayor la temperatura de referencia
		CBI PORTD,2
		RJMP refreshYadcRETI
	compararTemperaturaLSB:
		CP tempReal_LSB,tempRef_LSB
		BRLO conectarResistencia
		RJMP desconectarResistencia	;mayor o igual, desconectar resistencia
	conectarResistencia:
		SBI PORTD,2

	refreshYadcRETI:
		POP R15
		OUT SREG,R15
		RETI

teclado:
	LDI R17,4            ;cont de filas                  
	LDI R18,0xFE     ; código activación de filas                  
	LDI R19,3            ;valor mayor 1ra fila

	tecladoFila:     
		OUT PORTC,R18     ; activa filas                 
		NOP                 
		IN R16,PINC       ; lee columnas                 
		ANDI R16,0xF0     ; enmascarar filas                 
		CPI R16,0xF0                       
		BRNE tecla_pres   ;hay tecla oprimida                 
		SEC  
		ROL R18            ; rotar código de act de filas 
		SUBI R19,-4       ; sumar 4 a valor mayor de fila 
		DEC R17 
		BRNE tecladoFila      ; ver sgte fila                 
		LDI R19,0xFF       ; no hubo tecla oprimida 	
		RET
		
		tecla_pres:
			CALL retardo10ms  ;elimina rebote                  
			IN R16,PINC       ; lee columnas                  
			ANDI R16,0xF0     ; enmascarar filas  
			CPI R16,0xF0        
			BRNE tecladoColumna                  
			LDI R19,0xFF      ; no hubo tecla oprimida, ruido                  
			RET
		tecladoColumna:
			ROL R16                ; Verificar que columna fue la oprimida        
			BRCC tecladoSoltar        
			DEC r19        
			RJMP tecladoColumna
		tecladoSoltar: 
			IN R16,PINC          ; lee columnas           
			ANDI R16,0xF0        ; enmascarar filas           	
			CPI R16,0xF0             
			BRNE tecladoSoltar           
			CALL retardo10ms           
			RET		
	
BIN2BCD: 
	CLR R16                  
	STS 0x60,R16                  
	STS 0x61,R16  
	STS 0x62,R16  	
	STS 0x63,R16    
	otroBIN:  
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
					BRNE otroBIN         
					DEC BIN_MSB         
					RJMP otroBIN

BCD2BIN:
	LDS R20,0x63     ; Pasar dato a convertir de RAM de display a 0x70 a 0x73
	STS 0x73,R20
	LDS R20,0x62
	STS 0x72,R20
	LDS R20,0x61
	STS 0x71,R20
	LDS R20,0x60
	STS 0x70,R20
	otroBCD:  
		LDS R20,0x73          ;Terminar cuando BCD=0         
		CPI R20,0         
		BRNE DEC_BCD         
		LDS R20,0x72         
		CPI R20,0         
		BRNE DEC_BCD         
		LDS R20,0x71         
		CPI R20,0         
		BRNE DEC_BCD          
		LDS R20,0x70          
		CPI R20,0          
		BRNE DEC_BCD          
		RET
			
		DEC_BCD: 
			LDI R17,9         ; Decrementar BCD     
			LDI YL,0x73     
			LDI YH,0
			ciclo: 
				LD R20,Y             
				DEC R20             
				ST Y,R20             
				CPI R20,0xFF              
				BRNE INC_BIN              
				ST Y, R17               
				DEC YL               
				CPI YL,0x6F	;Checar para 4 dígitos
				BRNE ciclo
				INC_BIN: 
					INC BIN_LSB        ; Incrementar binario 
					CPI BIN_LSB,0  
					BRNE otroBCD   
					INC BIN_MSB   
					RJMP otroBCD

refresh:
	LD R0,X+	;Leer RAM
	MOV R20,R25	;código de barrido a R20
	ANDI R20,0xF0	;Enmascarar código de barrido
	ADD R0,R20	;Sumar número a mostrar en parte baja
	OUT PORTB,R0	;Mostrar por el puerto
	ROL R25	;Rotar
	DEC R24	;Decrementar contador
	BRNE refreshRET
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,4	;contador
	LDI R25,0b11101111	;código de barrido para display7seg ánodo común x4
	refreshRET:
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