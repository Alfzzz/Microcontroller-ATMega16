/*2-  Un  sistema  basado  en  ATMEGA  16  permite  establecer  los  niveles  de  volumen  de  dos canales  de  comunicaciones  de  datos.  (Canal  1  y  Canal  2).  El  sistema  dispone  de  los siguientes elementos:

-Un interruptor ON/OFF, que selecciona el canal activo en un momento dado. 

-Dos teclas +/-, que permitirán aumentar o disminuir en un paso el nivel de volumen, del canal seleccionado. El nivel de volumen puede ser variado de 0 a 30. Cada canal puede tener un nivel de volumen diferente. Se deben verificar que no se sobrepasen los límites máximos y mínimos de volumen (0 y 30), en cuyo caso no se le permitirá al usuario aumentar o disminuir.

-Un  display  de  3  lámparas  7s,  en  la  primera  se  visualiza  el  número  del  canal seleccionado y en las dos restantes su  nivel de volumen.

-Cada  vez  que  se  aumente  o  disminuya  el  nivel  de  volumen  de  un  canal  se  debe enviar dicho valor por puerto serial a un sistema de control. El valor se enviará en formato BCD compactado en 8 bits (las unidades son los 4 bits LSB y las decenas los  4  bits  MSB).  Se  dsipone  de  os  líneas  de  puerto  adicionales  para  indicar  a  que canal se está envieando el dato.La Transmisión se hará a 9600 baudios.

Realice  el  diseño  del  hardware  y  software  del  sistema.  Realice  la  atención  a  las  teclas  +/- por interrupción. (frec_ cristal = 8 Mhz). */

.DEF BIN_LSB=R22
.DEF BIN_MSB=R23
.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 2
RJMP switch
.ORG 4
RJMP menos
.ORG 0x24
RJMP mas
.ORG 0x26
RJMP refresh

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	
	;Puertos
	SER R16
	OUT DDRB,R16	;Displays 7seg x4
	SBI DDRD,1	;Salida Tx
	SBI DDRD,6	;inicador de canal 1
	SBI DDRD,7	;incador de canal 2
	SBI DDRD,1	;Tx

	;Preparar refrescamiento	
	CLR XH
	LDI XL,0x60
	LDI R24,3	;Contador de displays
	LDI R25,0b11101111	;Barrido

	;refresh
	LDI R16,0b00000010	;OCIE0
	OUT TIMSK,R16
	LDI R16,51 ;(1/(3*50Hz))/125ns/1024-1=51
	OUT OCR0,R16
	LDI R16,0b00001101	;CTC, prescaler 1024
	OUT TCCR0,R16

	;Serial
	LDI R16,0b10000110	;seleccionar registro UCSRC, enviar 8 bits
	OUT UCSRC,R16
	LDI R16,0b00001000	;Habilitar transmisión
	OUT UCSRB,R16	;9600 baudios	
	LDI R16,0
	OUT UBRRH,R16
	LDI R16,51
	OUT UBRRL,R16
	
	;Interrupciones
	LDI R16,0b11100000	;INT1,INT0,INT2
	OUT GICR,R16
	LDI R16,0b00001101	;flanco de subida para tecla+(INT1) y cambio de nivel para switch(INT0)
	OUT MCUCR,R16
	LDI R16,0b01000000	;flanco de subida para tecla-(INT2)
	SEI
	fin:
		RJMP fin
	

switch:
	IN R15,SREG
	PUSH R15

	SBIC PIND,2
	RJMP canal2
	
	canal1:
		CLT
		LDI R16,1
		STS 0x60,R16
		RJMP switchRETI
	canal2:
		SET
		LDI R16,2
		STS 0x60,R16
	
	switchRETI:
		POP R15
		OUT SREG,R15
		RETI
	
mas:
	IN R15,SREG
	PUSH R15

	BRTC incrementarCanal1
	incrementarCanal2:
		SBI PORTD,7	;Indicar que se envía por canal 2
		INC R22
		CPI R22,31
		BREQ canal2_30
		LDI BIN_LSB,R22
		RJMP enviarMas
		canal2_30:
			LDI R22,30
			LDI BIN_LSB,R22
			RJMP enviarMas
	incrementarCanal1:
		SBI PORTD,6	;Indicar que se envía por canal 1
		INC R21
		CPI R21,31
		BREQ canal1_30
		LDI BIN_LSB,R21
		RJMP enviarMas
		canal1_30:
			LDI R21,30
			LDI BIN_LSB,R21

	enviarMas:
		LDI BIN_MSB,0
		CALL BIN2BCD
		LDS R16,0x72	;MSB
		STS 0x61,R16
		LDS R17,0x73	;LSB
		STS 0X62,R17
		SWAP R16
		ADD R16,R17
		OUT UDR,R16
		pollingEnviarMenosCanal1:
		SBIS UCSRA,UDRE
			RJMP pollingEnviarMenosCanal1
		;fin de transmisión
		CBI PORTD,6
		CBI PORTD,7
	masRETI:
		POP R15
		OUT SREG,R15
		RETI
menos:
	IN R15,SREG
	PUSH R15

	BRTC decrementarCanal1
	decrementarCanal2:
		SBI PORTD,7	;Indicar que se envía para canal 2
		DEC R22
		CPI R22,255
		BREQ canal2_0
		LDI BIN_LSB,R22
		RJMP enviarMenos
		canal2_0:
			CLR R22
			LDI BIN_LSB,R22
			RJMP enviarMenos

	decrementarCanal1:
		SBI PORTD,6	;Indicar que se envía para canal 1
		DEC R21
		CPI R21,255
		BREQ canal1_0
		LDI BIN_LSB,R21
		RJMP enviarMenos
		canal1_0:
			CLR R21
			LDI BIN_LSB,R21
	enviarMenos:
		LDI BIN_MSB,0
		CALL BIN2BCD
		LDS R16,0x72	;MSB
		STS 0x61,R16
		LDS R17,0x73	;LSB
		STS 0X62,R17
		SWAP R16
		ADD R16,R17
		OUT UDR,R16
		pollingEnviarMenosCanal1:
		SBIS UCSRA,UDRE
			RJMP pollingEnviarMenosCanal1
		;fin de transmisión
		CBI PORTD,6
		CBI PORTD,7

	menosRETI:		
		POP R15
		OUT SREG,R15
		RETI	

BIN2BCD:	;Inicializar BCD en |0|0|0|0|
	CLR R16
	STS 0x70,R16	
    STS 0x61,R16     
	STS 0x72,R16     
	STS 0x73,R16

otro:  
	CPI BIN_LSB,0	;Checar si la parte baja del valor binario llegó a 0      
	BRNE INC_BCD    ;En el caso de que no, volver a incrementar BCD       
	CPI BIN_MSB,0   ;Checar si la parte alta del valor bianrio llegó a 0        
	BRNE INC_BCD    ;En el caso de que no, volver a incrementar BCD       
	RET	;Terminar el proceso y ya se convirtió el binario a BCD

//-- lógica: se incrementa el número BCD mientras se decrementa el binario hasta que sea 0.
 INC_BCD: 
	LDI R17,0     ;Registro utilizado para resetear en el caso de que llegue a 10 
	LDI YL,0x73    ;Dirección para dígitos BCD parte baja  
	LDI YH,0	;Dirección de unidades parte alta
ciclo: 
	LD R20,Y ;R24 es el registro de contador BCD de 1 a 9, traerse el valor de la memoria RAM           
	INC R20  ;Incrementar el contador de BCD   
	ST Y,R20 ;Guardar de vuelta valor incrementado     
	CPI R20,10	;Checar si se llegó a 10      
	BRNE DEC_BIN	;En caso de que no sea 10, decrementar valor binario      
	ST Y, R17	;Resetear el valor de BCD en caso que haya llegado a 10      
	DEC YL	;Decrementar el apuntador para que vaya a continuación a incrementar por el "10" que corresponde       
	CPI YL,0x5F	;Checar si llegó a 0x5F, en teoría puede ser cualquier valor diferente de las direcciones de RAM      
	BRNE ciclo	

DEC_BIN: 
	DEC BIN_LSB ;Decrementar valor binario     
	CPI BIN_LSB,0xFF	;Checar si se restó de 0, inidicación para restar parte alta         
	BRNE otro	;En el caso de que no haya llegado a menor de 0 la resta, volver a hacer la operación       
	DEC BIN_MSB	;En el caso de que se restó de 0, restar parte alta        
	RJMP otro	;Volver a hacer la operación
	