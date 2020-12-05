/*1-) Se quiere diseñar con un microcontrolador ATmega16 un equipo que entrega al procesador un valor digital de 8 bits, proveniente de un sistema de posicionamiento de una antena. A partir de la opresión de una tecla, el procesador debe leer un valor digital cada  2 seg  y almacenarlo en SRAM  hasta completar 500 muestras.Cuando se hayan completado la adquisición de las 500 muestras se debe encender un led de aviso y generar  por  una  línea  de  puerto  un  tren  de  pulsos  de  200ms  en  “0”  y  300ms  en  “1”.  El  tren  de pulsos se generará hasta que se reciba una señal activa en “0” proveniente de una computadora que indicará que finalice el tren de pulsos y se apague el led.1-   Realice el diseño completo del Hardware del sistema. 2-   Realice el diseño completo del software. Utilice la rutina de retardo de 10ms para  TODOS los requerimientos de tiempo del sistema. (frec_reloj=8Mhz).*/
.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Configuración de puertos, PB0 tecla, PB1 señal de computadora, PB2 LED, PB3 señal de pulsos 
SBI DDRB,2
SBI DDRB,3

PollingTeclado:	;AntiRebote
	SBIC PINB,0
	RJMP PollingTeclado
CALL retardo10ms
SBIC PINB,0
RJMP PollingTeclado	;Tomar valor para ver si fue ruido
Wait:
	SBIS PINB,0
	RJMP Wait	;Esperar a que se suelte
CALL retardo10ms

;Leer 500 valores digitales en el puerto A
Puntero memoria RAM
LDI XL,LOW(0x100)
LDI XH,HIGH(0x100)

LDI R16, 2
ciclo2:
	LDI R17,250
ciclo250:
	IN R18,PINA
	ST X+,R16
	CALL retardo2s
	DEC R17
	BRNE ciclo250
	DEC R16
	BRNE ciclo2
SBI PORTB,2	;Prender LED por PB2	
LecturaSeñal:	Tren de  pulsos por PB3
	CBI PORTB,3
	CALL retardo200ms
	SBI PORTB,3
	CALL retardo300ms
	CBI PORTB,3
	SBIC PINB,1			
	RJMP LecturaSeñal
	CBI PORTB,2 Apagar LED
	RJMP PollingTeclado

retardo300ms:
	LDI R24,30
	ciclo4:
		CALL retardo10ms
		DEC R24
		BRNE ciclo4
RET		

retardo200ms:
	LDI R23,20
	ciclo3:
		CALL retardo10ms
		DEC R23
		BRNE ciclo3
RET		

		
retardo2s:
	LDI R22,200
	ciclo3:
		CALL retardo10ms
		DEC R22
		BRNE ciclo3
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