/*Realice un programa que atienda una tecla por interrupción externa y un display de 4dígitos  ánodo común. El programa debe decrementar en “1” el valor del display por cada opresión de la tecla. El valor inicia en “9999”.*/

.INCLUDE "m16def.inc"
.ORG 0
RJMP main
.ORG 2
RJMP tecla
.ORG 0x26
RJMP refresh

main:
	;Pila
	LDI R16,LOW(RAMEND)
	OUT SPL,R16
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	
	SER R16
	OUT DDRB,R16	
	LDI R16,0b01000000 ;INT 0
	OUT GICR,R16
	LDI R16,0b00000010
	OUT MCUCR,R16	;Detectar flanco de bajada para INT0 
	OUT TIMSK,R16	;OCIE0
	LDI R16,38	;timer de 5ms para refrescar 4 displays
	OUT OCR0,R16
	LDI R16,0b00001101	;modo CTC ,prescaler de 1024 	
	OUT TCCR0,R16
	
	;preparar refresh
	LDI XH,HIGH(0x60)	;Apuntador a RAM
	LDI XL,LOW(0x60)
	LDI R24,4	;Contador de displays
	LDI R25,0b11101111	;código de barrido
	LDI R16,9
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	STS 0x63,R16

	SEI
	fin:
		RJMP fin

refresh:
	IN R20,SREG	;Salvar el entorno
	PUSH R20
	
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
		POP R20
		OUT SREG,R20
		RETI

tecla:
	IN R16,SREG
	PUSH R16

	CALL retardo10ms
	SBIC PIND,2
	RJMP teclaRETI
	SEI	;dejar que entre la interrupción de refresh
	teclaPolling:
		SBIS PIND,2
		RJMP teclaPolling
	CALL retardo10ms

	;Decrementar BCD
	LDI R17,9 ;registro para poner en 9 después
	LDS R16,0x63	;Leer unidades
	DEC R16
	STS 0x63,R16
	CPI R16,255
	BRNE teclaRETI
	STS 0x63,R17 ;poner unidades en 9 si llegó a menor de 0
	LDS R16,0x62	;Leer decenas
	DEC R16
	STS 0x62,R16
	CPI R16,255
	BRNE teclaRETI
	STS 0x62,R17	;poner decenas en 9 si llegó a menor de 0
	LDS R16,0x61	;Leer centenas
	DEC R16
	STS 0x61,R16
	CPI R16,255
	BRNE teclaRETI
	STS 0x61,R17	;poner centenas em 9 si llegó a menor de 0
	LDS R16,0x60	;Leer Millares
	DEC R16
	STS 0x60,R16
	CPI R16,255
	BRNE teclaRETI
	STS 0x60,R17	;poner millares en 9 si llegó a menor de 0
	teclaRETI:
		POP R16
		OUT SREG,R16
		RETI
/*
cteT1=T/Tr=10ms/125ns=80000 no cabe en 8 bits
cteT2=T/Tr=10ms/(1024*125ns)=78 cabe en 8 bits con prescaler de 1024
cargar 78-1=77 en OCR2
Palabra de control 00001111 modo ctc con prescaler 1024
*/
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