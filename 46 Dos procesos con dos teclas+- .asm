/*3-  Un  sistema  basado  en  ATMEGA  permite  establecer  los  niveles  de  presi�n  de  dos  procesos industriales (proceso 1 y proceso 2). El sistema dispone de los siguientes elementos:
-Un interruptor ON/OFF, que selecciona el proceso activo en un momento dado. El nivel de presi�n  puede  ser  variado  de  0  a  50.  Cada  proceso  puede  tener  un  nivel  de  presi�n diferente.
-Dos  teclas  +/-,  que  permitir�n  aumentar  o  disminuir  en  un  paso  el  nivel  de  presi�n,  del proceso seleccionado. El sistema debe verificar que el nivel seleccionado no sobrepase los l�mites m�ximo y m�nimo.
-Un display de 3 l�mparas 7s. En la primera se visualizar� el n�mero del proceso activo (1 � 2)  y  en  las  dos  restantes  el  nivel  de  presi�n  para  ese  proceso,  el  cual  se  ir�  modificando con la acci�n de las teclas.
-Dos  l�neas  de  salida  (una  para  cada  proceso)  por  la  cual  se  env�a  un  pulso  de  50ms  de duraci�n cuyo ciclo �til es en ms, el nivel de presi�n actual. El pulso se debe enviar cada vez que se oprima cualquiera de las teclas +/-
Realice el dise�o del Hardware y el Software del sistema..  Frecuencia del cristal=8 MHz*/

.INCLUDE "m16def.inc"
.def BIN_LSB=R19
.def BIN_MSB=R20
.ORG 0x0	;Reset
RJMP main
.ORG 0x2	;INT0
RJMP switch
.ORG 0x4	;INT1
RJMP teclaMenos
.ORG 0x24	;INT2
RJMP teclaMas
.ORG 0x26	;T0 compare
RJMP refresh

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	
	;Configuraci�n de puertos
	LDI R16,0XFF
	OUT DDRB,R16	;salida de displays
	SBI DDRD,4	;PWM proceso 1
	SBI DDRD,5	;PWM proceso 2

	;Interrupciones
	LDI R16,0b00000010	;OCIE0 habilitado
	OUT TIMSK,R16
	LDI R16,0b11100000	;habilitar ,INT0,INT1,INT2
	OUT GICR,R16
	LDI R16,0b00001101	;Detectar flanco de subida para INT1, cambio de nivel para INT0 
	OUT MCUCR,R16
	LDI R16,0b01000000	;Detectar flanco de subida para INT2 
	OUT MCUCSR,R16
	SEI
		
	;Preparar refrescamiento	
	LDI XH,HIGH(0x60)	;Apuntador a RAM para los displays
	LDI XL,LOW(0x60)
	LDI R24,3	;contador de display
	LDI R25,0b11101111	;C�digo de barrido

	
	;Configurar timers
	;Timer 0
	LDI R16,51	;OCR0=(1/(n*50Hz))/(1024*Tc)-1=(1/(3*50))/(1024*125ns)-1=51
	OUT OCR0,R16
	LDI R16,0b00001101	;CTC prescaler de 1024 para timer 0
	OUT TCCR0,R16
	;Timer 1 para PWM, se�al de 50ms, TOP=Fclock/Fs/N-1=8M/(1/50m)/64-1=6249
	LDI R16,HIGH(6249)
	OUT ICR1H,R16
	LDI R16,LOW(6249)
	OUT ICR1L,R16
		
	fin:
		RJMP fin

switch:
	SBIC PIND,2
	RJMP proceso2
	proceso1:
	SET	;T en 1 indica proceso1 
	LDI R16,1
	STS,0x62,R16	;0x62 tendr� el n�mero del proceso		
	RJMP  switchRETI

	proceso2:
	CLT	;T en 0 indica proceso 2
	LDI R16,2
	STS 0x62,R16	;0x62 tendr� el n�mero del proceso
	switchRETI:
		RETI

teclaMas:
	IN R16,SREG
	PUSH R16
	CALL retardo10ms
	SBIC PINB,2
	RJMP teclaRETI
	SEI	;dejar que entre la interrupci�n de refresh
	teclaMasPolling:
		SBIS PINB,2
		RJMP teclaMasPolling
	CALL retardo10ms

	SBIC SREG,T	;Checar si estuvo en el proceso 1 o en el proceso 2
	RJMP,incrementarPresion1	;Estuvo en el proceso 1

	incrementarPresion2:
		INC R22
		CPI R22,51	;Checar si sobrepas� de 50 al incrementar
		BRLO incrementarPresion2Seguir	
		LDI R22,50	;Regresar a 50 si es que sobrepas� 50
		incrementarPresion2Seguir:
			LDI R16,125	;Tope del T1/50=6249/50=125
			MUL R22,R16		
			OUT OCR1BH,R1	;presi�n 2 sale por la OCR1B, parte alta de la multiplicaci�n
			OUT OCR1BL,R0	;Parte baja de la multiplicaci�n
			LDI R16,0b00100010	;Clear OC1B y modo 14
			OUT TCCR1A,R16
			LDI R16,0b00011011	;Modo 14 y prescaler de 64	
			OUT TCCR1B,R16
			LDI BIN_MSB,0	;Cargar parte alta
			MOV BIN_LSB,R22	;Cargar parte baja, la presi�n 2
			CALL BIN_BCD	;Convertir binario a BCD
			LDI R16,2	;n�mero de proceso 2
			STS,0x62,R16	;0x62 tendr� el n�mero del proceso
			RJMP teclaMasRETI
		
	incrementarPresion1:
		INC R21
		CPI R21,51
		BRLO incrementarPresion2Seguir
		LDI R21,50
		incrementarPresion1Seguir:
			LDI R16,125	;Tope del T1/50=6249/50=125
			MUL R21,R16		
			OUT OCR1AH,R1	;presi�n 2 sale por la OCR1A, parte alta de la multiplicaci�n
			OUT OCR1AL,R0	;Parte baja de la multiplicaci�n
			LDI R16,0b10000010	;Clear para OC1A y modo 14
			OUT TCCR1A,R16
			LDI R16,0b00011011	;Modo 14 y prescaler de 64	
			OUT TCCR1B,R16
			LDI BIN_MSB,0	;Parte alta del n�mero de 16 bits 
			MOV BIN_LSB,R21	;Parte baja, la presi�n 1
			CALL BIN_BCD	;Convertir n�mero 
			LDI R16,1	;n�mero del proceso 1
			STS,0x62,R16	;0x62 tendr� el n�mero del proceso
			RJMP teclaMasRETI
		
	teclaMasRETI:
		POP R16
		OUT SREG,R16
		RETI		

teclaMenos:
	IN R16,SREG
	PUSH R16
	CALL retardo10ms
	SBIC PIND,3
	RJMP teclaRETI
	SEI	;dejar que entre la interrupci�n de refresh
	teclaMenosPolling:
		SBIS PIND,3
		RJMP teclaMenosPolling
	CALL retardo10ms
	SBIC SREG,T	;Checar si estuvo en el proceso 1 o en el proceso 2
	RJMP,decrementarPresion1	;Estuvo en el proceso 1

	decrementarPresion2:
		DEC R22
		CPI R22,255	;Checar si sobrepas� de 50 al incrementar
		BRNE decrementarPresion2Seguir	
		LDI R22,0	;Regresar a 50 si es que sobrepas� 50
		decrementarPresion2Seguir:
			LDI R16,125	;Tope del T1/50=6249/50=125
			MUL R22,R16		
			OUT OCR1BH,R1	;presi�n 2 sale por la OCR1B, parte alta de la multiplicaci�n
			OUT OCR1BL,R0	;Parte baja de la multiplicaci�n
			LDI R16,0b00100010	;Clear OC1B y modo 14
			OUT TCCR1A,R16
			LDI R16,0b00011011	;Modo 14 y prescaler de 64	
			OUT TCCR1B,R16
			LDI BIN_MSB,0
			MOV BIN_LSB,R22
			CALL BIN_BCD
			LDI R16,2
			STS,0x62,R16	;0x62 tendr� el n�mero del proceso
			RJMP teclaMenosRETI
		
	decrementarPresion1:
		DEC R21
		CPI R21,255
		BRNE decrementarPresion2Seguir
		LDI R21,0
		decrementarPresion1Seguir:
			LDI R16,125	;Tope del T1/50=6249/50=125
			MUL R21,R16		
			OUT OCR1AH,R1	;presi�n 2 sale por la OCR1A, parte alta de la multiplicaci�n
			OUT OCR1AL,R0	;Parte baja de la multiplicaci�n
			LDI R16,0b10000010	;Clear para OC1A y modo 14
			OUT TCCR1A,R16
			LDI R16,0b00011011	;Modo 14 y prescaler de 64	
			OUT TCCR1B,R16
			LDI BIN_MSB,0
			MOV BIN_LSB,R21
			CALL BIN_BCD
			LDI R16,1
			STS,0x62,R16	;0x62 tendr� el n�mero del proceso
			RJMP teclaMenosRETI
		
	teclaMenosRETI:
		POP R16
		OUT SREG,R16
		RETI		

refresh:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
	LD R2,X+	;Leer RAM
	MOV R20,R25	;c�digo de barrido a R20
	ANDI R20,0xF0	;Enmascarar c�digo de barrido
	ADD R2,R20	;Sumar n�mero a mostrar en parte baja
	OUT PORTB,R2	;Mostrar por el puerto
	ROL R25	;Rotar
	DEC R24	;Decrementar contador
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,3	;contador
	LDI R25,0b11101111	;c�digo de barrido para display7seg �nodo com�n x3
	refreshRETI:
		POP R20
		OUT SREG,R20
		RETI
	


//-- Espacio de memoria en RAM donde se guarda el n�mero convertido en BCD
BIN_BCD:	;Inicializar BCD en |0|0|0|0|
	CLR R16
	STS 0x60,R16	
    STS 0x61,R16     
	STS 0x62,R16     
	STS 0x63,R16

otro:  
	CPI BIN_LSB,0	;Checar si la parte baja del valor binario lleg� a 0      
	BRNE INC_BCD    ;En el caso de que no, volver a incrementar BCD       
	CPI BIN_MSB,0   ;Checar si la parte alta del valor bianrio lleg� a 0        
	BRNE INC_BCD    ;En el caso de que no, volver a incrementar BCD       
	RET	;Terminar el proceso y ya se convirti� el binario a BCD

//-- l�gica: se incrementa el n�mero BCD mientras se decrementa el binario hasta que sea 0.
 INC_BCD: 
	LDI R17,0     ;Registro utilizado para resetear en el caso de que llegue a 10 
	LDI YL,0x63    ;Direcci�n para d�gitos BCD parte baja  
	LDI YH,0	;Direcci�n de unidades parte alta
ciclo: 
	LD R20,Y ;R24 es el registro de contador BCD de 1 a 9, traerse el valor de la memoria RAM           
	inc R20  ;Incrementar el contador de BCD   
	ST Y,R20 ;Guardar de vuelta valor incrementado     
	CPI R20,10	;Checar si se lleg� a 10      
	BRNE DEC_BIN	;En caso de que no sea 10, decrementar valor binario      
	ST Y, R17	;Resetear el valor de BCD en caso que haya llegado a 10      
	DEC YL	;Decrementar el apuntador para que vaya a continuaci�n a incrementar por el "10" que corresponde       
	CPI YL,0x5F	;Checar si lleg� a 0x5F, en teor�a puede ser cualquier valor diferente de las direcciones de RAM      
	BRNE ciclo	

DEC_BIN: 
	DEC BIN_LSB ;Decrementar valor binario     
	CPI BIN_LSB,0xFF	;Checar si se rest� de 0, inidicaci�n para restar parte alta         
	BRNE otro	;En el caso de que no haya llegado a menor de 0 la resta, volver a hacer la operaci�n       
	DEC BIN_MSB	;En el caso de que se rest� de 0, restar parte alta        
	RJMP otro	;Volver a hacer la operaci�n	
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
