/*1-)   Diseñar      usando   un   ATMEGA16   un   cronómetro   digital   que   entregue   en   4   lámparas 7segmentos el tiempo en segundos y centésimas de segundo. La base mínima de conteo será de 1 centésima de segundo (10 ms). El conteo se inicia con una tecla “START”, sin rebote y se debe visualizar  en  el  display  el  tiempo  transcurrido.  El  conteo  se  detiene  cuando  se  intercepta  un  haz lumínico. Esta señal es activa en “0” y será atendida por interrupción. El sistema dispone además de una tecla “CLEAR” que permite limpiar el display para una próxima medición.
Realice el diseño del Hardware y el Software del sistema. Utilice la rutina de refrescamiento vista en clase. Frecuencia del cristal=8 MHz*/

.INCLUDE "m16def.inc"
.ORG 0	;Reset
RJMP main
.ORG 2	;INT0, haz lumínico
RJMP hazLuminico
.ORG 4	;INT1, start
RJMP start
.ORG 0x6	;OC2 para 10ms
RJMP incremento
.ORG 0x24	;INT2 clear
RJMP clear
.ORG 0x26	;OC0 para refrescar
RJMP refresh

main:
	;Pila
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	
	;Puertos
	SER R16
	OUT DDRA,R16

	;Interrupciones	
	LDI R16,0b11100000 ;INT0,INT1,INT2
	OUT GICR,R16
	LDI R16,0b00001010
	OUT MCUCR,R16	;Detectar flanco de bajada para INT0,flanco de bajada para INT1
	LDI R16,0b00000000	;detectar flanco de bajada para INT2 
	OUT MCUCSR,R16
	LDI R16,0b10000010	
	OUT TIMSK,R16	;OCIE2,OCIE0
	SEI
	
	;Timers
	LDI R16,38	;OCR0=(1/(4*50Hz))/125ns/1024-1=38
	OUT OCR0,R16		
	LDI R16,0b00001101	;modo CTC ,prescaler de 1024 	
	OUT TCCR0,R16	

	;preparar refresh
	LDI XH,HIGH(0x60)	;Apuntador a RAM
	LDI XL,LOW(0x60)
	LDI R24,4	;Contador de displays
	LDI R25,0b11101111	;código de barrido ándo común
	CLR R16
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	STS 0x63,R16

	SEI
	fin:
		RJMP fin
hazLuminico:
	IN R20,SREG	;Salvar el entorno
	PUSH R20

	CLR,R16 	
	OUT TCCR2,R16	;Detener conteo, apagar timer
	POP R20
	OUT SREG,R20
	RETI
	
start:
	IN R20,SREG	;Salvar el entorno
	PUSH R20

	LDI R16,77	;OCR2=10ms/125ns/1024-1=77
	OUT OCR2,R16
	LDI R16,0b00001111	;modo CTC ,prescaler de 1024 	
	OUT TCCR2,R16
	LDI R23,100	;contador para contar 100*10ms=1s
	POP R20
	OUT SREG, R20
	RETI
	
refresh:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
	LD R0,X+	;Leer RAM
	MOV R20,R25	;código de barrido a R20
	ANDI R20,0xF0	;Enmascarar código de barrido
	ADD R0,R20	;Sumar número a mostrar en parte baja
	OUT PORTA,R0	;Mostrar por el puerto
	ROL R25	;Rotar
	DEC R24	;Decrementar contador
	BRNE refreshRETI
	LDI XL,LOW(0x60)	;puntero A RAM para el display
	LDI XH,HIGH(0x60)
	LDI R24,4	;contador
	LDI R25,0b11101111	;código de barrido para display7seg ánodo común x4
	refreshRETI:
		POP R20
		OUT SREG,R20
		RETI

incremento:
	IN R16,SREG
	PUSH R16
	
	SBIS PINB,1	;Checar qué escala se quiere trabajar
	RJMP escala10ms	;ir a esala10ms si el switch está en 0
	DEC R23
	BRNE incrementoRETI
	escala10ms:
		LDI R23,1OO	;resetear el contador si es que la escala es de 1s
		
		
	;Incrementar BCD
	CLR R17 ;registro para resetear después
	LDS R16,0x63	;Leer unidades
	INC R16
	STS 0x63,R16
	CPI R16,10
	BRNE teclaRETI
	STS 0x63,R17 ;Resetear si unidades llegó a 10
	LDS R16,0x62	;Leer decenas
	INC R16
	STS 0x62,R16
	CPI R16,10
	BRNE teclaRETI
	STS 0x62,R17	;Resetear si decenas llegó a 10
	LDS R16,0x61	;Leer centenas
	INC R16
	STS 0x61,R16
	CPI R16,10
	BRNE teclaRETI
	STS 0x61,R17	;Resetear centenas
	LDS R16,0x60	;Leer Millares
	INC R16
	STS 0x60,R16
	CPI R16,10
	BRNE teclaRETI
	STS 0x60,R17	;Resetear millares
	incrementoRETI:
		POP R16
		OUT SREG,R16
		RETI

clear:
	IN R20,SREG	;Salvar el entorno
	PUSH R20

	;Eliminador de rebote
	CALL retardo10ms
	SBIC PINB,2
	RJMP clearRETI
	SEI	;dejar que entre la interrupción de refresh
	clearPolling:
		SBIS PINB,2
		RJMP clearPolling
	CALL retardo10ms

	CLR,R16 	
	OUT TCCR2,R16	;Detener conteo, apagar timer 2
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	STS 0x63,R16
	POP R20
	OUT SREG,R20
	RETI

retardo10ms:
	PUSH R20
	PUSH R21
	LDI R20,104
	ciclo2:
		LDI R21,255
	ciclo1:
		DEC R21
		BRNE ciclo1
		DEC R20
		BRNE ciclo2
	POP R21
	POP R20
RET
