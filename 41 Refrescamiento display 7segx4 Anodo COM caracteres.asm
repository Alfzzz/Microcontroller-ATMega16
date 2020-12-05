/*Refrescamiento de display 7 segmetnos Ánodo común x4 para visualizar caracteres(letras y números)
Visualizar HOLA
*/

.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 0x26	;Timer 0 compare
RJMP refreshCaracteres
	
main:
	;Pila
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	SER R16
	OUT DDRB,R16	;Puerto B como salida
	OUT DDRC,R16	;Puerto C como salida
	LDI R16,0b00000010
	OUT TIMSK,R16	;Habilitar OCIE0, interupcción timer0 compare
	LDI R16,38	;(1/(4*50Hz))/125ns/1024-1=38
	OUT OCR0,R16	
	LDI R16,0b00001101 ;Modo CTC, prescaler de 1024
	OUT TCCR0,R16

	;preparar RFSH
	LDI XL,LOW(0x60)	;puntero a RAM del display
	LDI XH,HIGH(0x60)	
	LDI R24,4	;Contador
	LDI R25,0b11111110	;Código de barrido

	;Cargar valores
	;LDI R16,0b11000000	;Código 7 segmentos de "0"
	;STS 0x60,R16
	;STS 0x61,R16
	;STS 0x62,R16
	;STS 0x63,R16
	
	;Leer ROM y pasarlo a RAM si es que está guardado HOLA en ROM
	LDI ZH,HIGH(0x300<<1)
	LDI ZL,LOW(0x300<<1)
	LDI YH,	HIGH(0x60)
	LDI YL, LOW(0x60)
	LDI R17,4	;Contador de caracteres
	cargarCaracteres:
		LPM,R16,Z+
		ST Y+,R16
		DEC R17
		BRNE cargarCaracteres

	SEI
	
	fin:
		RJMP fin
refreshCaracteres:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
	LD R0,X+	;Leer RAM
	OUT PORTB,R0	;enviar caracter 7seg
	IN R20,PORTC	;leer el puerto C
	ORI R20,0x0F ;Enmascarar parte MSB
	AND R20,R25	
	OUT PORTC,R20	;Código barrido
	SEC
	ROL R25
	DEC R24	;Decrementar contador
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,4	;contador
	LDI R25,0b11111110	;código de barrido
	refreshRETI:
		POP R20
		OUT SREG,R20
		RETI

.ORG 0x300
;Hola
.DB 0b10001001,0b1000000,0b11000111,0b10001000