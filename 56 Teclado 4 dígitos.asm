/*Realice un programa que atienda un teclado matricial de 4*4 y un display de 4 dígitos ánodo común. El sistema debe permitir la entrada de dígitos por teclado con la siguiente secuencia:

Inicio---->Dígitos----->Enter

Los dígitos capturados se deben mostrar en el display rotándolos de derecha a izquierdaEl sistema debe permitir entrar Dígitos hasta que se oprima la tecla Enter.*/

.INCLUDE "m16def.inc"
.ORG 0
RJMP main
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
	OUT DDRB,R16	;PB0-PB3 displays7seg x4 PB4-PB7 barrido
	LDI R16,0x0F ; PC0-PC3 (salidas)PC4-PC7 (entradas)
	OUT DDRC,R16   

	;preparar refresh
	LDI XL,LOW(0x60)	;puntero a RAM del display
	LDI XH,HIGH(0x60)	
	LDI R24,4	;Contador
	LDI R25,0b11101111	;Código de barrido

	;Valores iniciales de display
	LDI R16,0
	STS 0x60,R16
	STS 0x61,R16
	STS 0x62,R16
	STS 0x63,R16

	;Timer0 Interrupción
	LDI R16,0b00000010
	OUT TIMSK,R16	;Habilitar OCIE0, interupcción timer0 compare
	LDI R16,38	;(1/(4*50Hz))/125ns/1024-1=38
	OUT OCR0,R16	
	LDI R16,0b00001101 ;Modo CTC, prescaler de 1024
	OUT TCCR0,R16
	SEI

	tecladoInicio:
		CALL teclado
		CPI R19,10	;Checar si fue tecla de inicio
		BRNE tecladInicio
	tecladoDigitos:
		CALL teclado
		CPI R19,10	
		BRLO rotarDisplay	;Checar si fue dígito
		CPI R19,11	
		BRNE tecladoDigitos	;Checar si fue tecla de enter
		RJMP tecladoSeguir
		rotarDisplay:	;Recorrimiento
			LDS R16,0x61
			STS 0x60,R16	
			LDS R16,0x62
			STS 0x61,R16	
			LDS R16,0x63
			STS 0x62,R16	
			STS 0x63,R19	
			RJMP tecladoDigitos
	
	tecladoSeguir:

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
			CPI R16,0xF0        BRNE tecla                  
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
