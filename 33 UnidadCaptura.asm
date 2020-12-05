/*Ejercicio 8 Realice un programa que mida el tiempo en “1” ( duty Cycle)  de una señal de Frecuencia=60Hz utilizando la unidad de captura del timer 1.Muestre el resultado en el puerto B*/

/*
Unidad de captura en PD6
cteT1=(1/60)/125ns=132800 No cabe en ni en 16 bits ni en 8 bits
cteT2=(1/60)/(125ns*1024)=130 Prescaler de1024, sí cabe en 8 bits, porque se necesita sacar por el puerto B

Palabra de control:
TCCR1A=|COM1A1|COM1A0|COM1B1|COM1B0|FOC1A|FOC1B|WGM11|WGM10|=00000000 
TCCR1B=|ICNC1|ICES1|--|WGM13|WGM12|CS12|CS11|CS10|=0x000101 Modo normal, prescaler de 1024, Sin cancelador de ruido, x es 1 y luego 0 para capturar 2 veces(un flanco de subida y un flanco de bajada)
*/

.ORG 0
.INCLUDE "m16def.inc"

;Pila
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16

;Puertos
SER R16
OUT DDRB,R16 ;Resultado a la salida

CLR R16
OUT TCCR1A,R16
LDI R16,0b01000101	;Detectar flanco de subida
OUT TCCR1B,R16

PollingFlancoSubida:
	IN R16,TIFR
	SBRS R16,ICF1	;Esperar el flaco de subida
	RJMP PollingFlancoSubida
IN R20,ICR1L	;Solo es necesario la parte baja porque cabe en 8 bits
LDI R16,1<<ICF1
OUT TIFR,R16
LDI R16,0b00000101 	;Detectar flanco de bajada
OUT TCCR1B,R16
PollingFlancoBajada: 
	IN R16,TIFR
	SBRS R16,ICF1	;Esperar el flanco de bajada
	RJMP PollingFlancoBajada
IN R21,ICR1L
SUB R21,R20
OUT PORTB,R21
LDI R16,1<<ICF1
OUT TIFR,R16

;Lo que sigue el código,no se ha apagado el timer 1

