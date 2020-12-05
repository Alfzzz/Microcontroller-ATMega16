/*EjercicioRealice un programa que transmita por puerto serial un arreglo de 50 caracteresASCII ubicados en SRAM a partir de la dirección 0x60.
La transmisión serial seráA 9600 baudios con el siguiente formato:
-8 bits de datos
-1 bit de parada
- Sin paridad*/
/*
Agregar al sistema anterior la posibilidad de recibir por puerto serial un conjunto de 6 Bytes de una contraseña que permitirá activar una cerradura electrónica
*/

.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 0x16
RJMP rx
.ORG 0x18
RJMP tx

main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16

	SBI DDRD,1	;Salida de Tx

	;UCSRC=|URSEL|UMSEL|UPM1|UPM2|USBS|UCSZ1|UCSZ0|UCPOL|=10000110
	;Seleccionar UCSRC,asíncrono, sin paridad, un bit de parada, 8 bits de datos, sin polaridad de clock
	LDI R16,0b10000110		
	OUT UCSRC,R16	
	
	;UCSRB=|RXCIE|TXCIE|UDRIE|RXEN|TXEN|UCSZ2|RXB8|TXB8|=10111000	
	;Habilitar transmisión, recepción, interrupción por buffer de transmisión vacío, interrupción por buffer de recepción  lleno
	LDI R16,0b10111000	;
	OUT UCSRB,R16

	;Baudrate=9600------>UBRRH|UBRRL=51
	LDI R16,HIGH(51)
	OUT UBRRH,R16
	LDI R16,LOW(51)
	OUT UBRRL,R16

	;Preparación para transmisión
	LDI XH,HIGH(0x60)
	LDI XL,LOW(0x60)
	LDI R25,50	;Contador de 50 datos

	;Preparación para recepción
	LDI YH,HIGH(0x100)
	LDI YL,LOW(0x100)
	LDI R24,6

	SEI	;Empieza la transmisión porque el buffer empieza vacío
	fin:
		RJMP fin
tx:
	IN R15,SREG
	PUSH R15

	enviar:
		LD R16,X+
		OUT UDR,R16	;Transmitir
		DEC R25
		BRNE txRETI
		CLR R16	;termina la transmisión y se inhabilitan transmisión e interrupciones 
		OUT UCSRB,R16
	
	txRETI:
		POP R15
		OUT SREG,R15
		RETI
rx:
	IN R15,SREG
	PUSH R15
	
	IN R16,UDR
	ST Y+,R16
	DEC R24
	BRNE rxRETI
	;Comparar, acción, lo que se necesite después de leer 6 bytes
	txRETI:
		POP R15
		OUT SREG,R15
		RETI		