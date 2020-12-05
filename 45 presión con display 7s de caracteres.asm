/*2-) Dise�ar usando un ATMEGA16 un sistema para el control de presi�n de agua en un equipo de bombeo. El sistema recibe por un puerto de 8 bits un valor binario  que puede estar entre 0 y 9 que representa el nivel de presi�n medida.

La  medici�n  comienza  con  una  tecla  conectada  a  una  l�nea  de  interrupci�n  y  debe  medirse  cada 1seg. La medici�n se almacenar� en SRAM hasta un m�ximo de 50 muestras visualiz�ndose cada valor en una display de 3 l�mparas 7s de la siguiente forma:

P R  #   (# : Valor  de Presi�n) 
El  sistema  debe  comparar  la  presi�n  medida  con  un  valor  de  l�mite  superior  previamente seleccionado. Esta selecci�n se realiza mediante 3 interruptoresON/OFF, que seleccionan cada uno,  un  l�mite  superior  diferente  almacenado  en  memoria  ROM  a  partir  de  la  0x300  (Un  valor  de presi�n  l�mite  por  cada  interruptor).  Cuando  la  presi�n  medida  alcanza  el  l�mite  seleccionado  se debe abrir una v�lvula,  y visualizar dicho valor en el display de la forma: 

LS   # (# : L�mite de Presi�n) 
Los  caracteres  7s  de  los  d�gitos  del  0  al  9,  se  encuentran  almacenados  en  ROM  a  partir  de  la direcci�n 0x400 y a continuaci�n los de las letras utilizadas en el dise�o.
Realice el dise�o del Hardware y el Software del sistema. Frecuencia del cristal=8 MHz*/

.INCLUDE "m16def.inc"
.def BIN_LSB=R19
.def BIN_MSB=R20
.ORG 0x0	;Reset
RJMP main
.ORG 0x2	;INT0
RJMP tecla
.ORG 0x6	;TImer 2 compare
RJMP lectura
.ORG 0x26	;T0 compare
RJMP refreshCaracteres

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	
	;Configuraci�n de puertos
	LDI R16,0XFF
	OUT DDRB,R16	;Codigo 7seg	
	LDI R16,0x0F
	OUT DDRC,R16	; c�digo barrido
	SBI DDRD,7	;v�lvula


	;Interrupciones
	LDI R16,0b00000010	;OCIE0 habilitado
	OUT TIMSK,R16
	LDI R16,0b01000000	;habilitar INT2
	OUT GICR,R16
	LDI R16,0b00000010	;Detectar flanco de bajada para INT0 
	OUT MCUCR,R16
	SEI
		
	;Preparar refrescamiento	
	LDI XH,HIGH(0x60)	;Apuntador a RAM para los displays
	LDI XL,LOW(0x60)
	LDI R24,3	;contador de display
	LDI R25,0b11111110	;C�digo de barrido
	LDI R16,0
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	
	;Configurar timers
	;Timer 0 para refresh
	LDI R16,51	;OCR0=(1/(n*50Hz))/(1024*Tc)-1=(1/(3*50))/(1024*125ns)-1=51
	OUT OCR0,R16
	LDI R16,0b00001101	;CTC prescaler de 1024 para timer 0
	OUT TCCR0,R16
	;Timer 2 para 1s
	LDI R16,124 ;OCR0=1s/(64*Tc)-1=1s/(64*125)-1=124
	OUT OCR2,R16	
	fin:
		RJMP fin

tecla:
	IN R16,SREG
	PUSH R16

	CALL retardo10m
	SBIC PIND,2
	RJMP teclaRETI
	SEI	;dejar que entre la interrupci�n de refresh
	teclaPolling:
		SBIS PIND,2
		RJMP teclaPolling
		CALL retardo10ms
	
	LDI R16,0b00001100	;activar timer 2	
	OUT TCCR2,R16
	LDI YH,HIGH(0x100)
	LDI YL,LOW(0x100)
	LDI R23,50
	
	POP R16
	OUT SREG,R16
	RETI
lectura:
	IN R16,SREG
	PUSH R16

	IN R16,PINA	;Lecutra de presi�n
	ST Y+,R16	;Guardar en la RAM y post incremento
	LDI ZH,HIGH(0x300<<1)	;Leer limites parte alta
	LDI ZL,LOW(0x300<<1)	;Leer limites	parte baja
	DEC ZL	;Decrementar el apuntador, deber�a de leer haber un 0 como l�mite
	SBIC PINC,4	;leer switch 1
	INC ZL	;Incrementar si es que est� activo, se considera que solo uno puede estar activado
	SBIC PINC,5	:;Leer switch2
	INC ZL	;Incrementar si es que est� activo
	SBIC PINC,6	;Leer switch3
	INC ZL	;Incrementar si es que est� activo
	LPM R17,Z	;Leer el l�mite
	CP R16,R17	Comparar con la presi�n le�da
	BRSH limitePresion	;si es mayor o igual al l�mite, irse a limitePresion
	valorPresion:
		LDI ZH,HIGH(0x400<<1)	;apuntador de caracteres parte alta
		LDI ZL,LOW(0x400<<1)	;apuntador de caracteres parte baja
		ADD ZL,R16	;Agregar apuntador parte baja con la presi�n para obtener posici�n correspondiente
		LPM R17,Z	;Leer c�digo 7seg de la presi�n correspondiente
		STS 0x60,R17	;Guardar en primer d�gito para display 1
		LDI ZL, LOW(0x405<<1)	;direcci�n de c�digo 7 seg de "P" parte baja en ROM
		LPM R17,Z+	;Leer c�digo 7seg de "P" y post incremento para leer "r"
		ST 0x61,R17	;Guardar en segundo d�gito para display 2 
		LPM R17,Z	;Leer c�digo 7seg de "r"
		STS 0x62,R17	;Guardar en tercer d�gito para display 3
		DEC R23	;Decrementar contador de valores a leer
		BRNE lecturaRETI	
	limitePresion:
		LDI ZH,HIGH(0x400<<1)
		LDI ZL,LOW(0x400<<1)
		ADD ZL,R16
		LPM R17,Z
		ST 0x60,R17
		LDI ZL,LOW(0x406<<1) ;direcci�n de c�digo 7 seg de "L" parte baja en ROM
		LPM R17,Z+	;Leer c�digo 7seg de "L" y post incremento para leer "S"
		ST 0x61,R17	;Guardar en segundo d�gito para display 2 
		LPM R17,Z+	;Leer c�digo 7seg de "S"
		STS 0x62,R17	;Guardar en tercer d�gito para display 3
		DEC R23	;Decrementar contador de valores a leer
		SBI PIND,7 ;abrir v�lula
		BRNE lecturaRETI
	CLR R16	
	OUT TCCR2,R16	;Apagar timer porque ya son 50 muestras
	LDI R23,50	;Resetear contador de muestras
	lecturaRETI:
		POP R16
		OUT SREG,R16
		RETI	
refreshCaracteres:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
	LD R0,X+	;Leer RAM
	OUT PORTB,R0	;enviar caracter 7seg
	IN R20,PORTC	;leer el puerto C
	ORI R20,0x0F ;Enmascarar parte MSB
	AND R20,R25	
	OUT PORTC,R20	;C�digo barrido
	SEC
	ROL R25
	DEC R24	;Decrementar contador
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,3	;contador
	LDI R25,0b11111110	;c�digo de barrido
	refreshRETI:
		POP R20
		OUT SREG,R20
		RETI
;l�mites
.ORG 0x299
.DB 0,0,2,4,6
;c�digos 7seg �nodo com�n
.ORG 0x400
;tabla de 0,1,2,3,4,5,6,7,8,9,P,r,L,S
.DB 0b01000000, 0b01111001,0b00100100,0b00110000,0b0011001,0b00010010,0b00000010,0b1111000,0b00000000,0b00010000,0b00001100, 0b00001111,0b010001111,0b00010010