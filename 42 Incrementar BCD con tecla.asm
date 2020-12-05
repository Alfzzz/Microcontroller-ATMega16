/*Realice un programa que atienda una tecla por interrupción externa y un display de 4dígitos  ánodo común. El programa debe incrementar en “1” el valor del display por cada opresión de la tecla. El valor inicia en “0”.*/

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
	CLR R16
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
	teclaRETI:
		POP R16
		OUT SREG,R16
		RETI

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