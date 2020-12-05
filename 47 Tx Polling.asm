/*EjercicioRealice un programa que transmita por puerto serial un arreglo de 50 caracteresASCII ubicados en SRAM a partir de la dirección 0x60.
La transmisión serial seráA 9600 baudios con el siguiente formato:
-8 bits de datos
-1 bit de parada
- Sin paridad*/

.ORG 0
.INCLUDE "m16def.inc"

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

;UCSRB=|RXCIE|TXCIE|UDRIE|RXEN|TXEN|UCSZ2|RXB8|TXB8|=00001000	Habilitar transmisión
LDI R16,0b00001000	;
OUT UCSRB,R16

;Baudrate=9600------>UBRRH|UBRRL=51
LDI R16,HIGH(51)
OUT UBRRH,R16
LDI R16,LOW(51)
OUT UBRRL,R16

CALL tx

fin:
	RJMP fin


tx:
	LDI XH,HIGH(0x60)
	LDI XL,LOW(0x60)
	LDI R25,50	;Contador de 50 datos
	enviar:
		LD R16,X+
		OUT UDR,R16
		pollingTx:
			SBIS UCSRA,UDRE	;Esperar a que se vacíe buffer de transmisión
			RJMP pollingTx
		DEC R25
		BRNE enviar
RET
		

