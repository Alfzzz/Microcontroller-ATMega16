/*2-) Un sistema basado ATMEGA16 debe controlar el movimiento de un carro que se desplaza por un  riel  en  posición  horizontal  a  partir  de  una  posición  central  y  en  ambos  sentidos  (izquierda    - derecha).

El  proceso  comienza  cuando  se  recibe  una  señal  de  control  activa  en  “0”,  que  será  atendida  por interrupción  externa.  El  sistema  debe  leer  por  un  puerto  un  valor  de  7  bits  entre  0  y  127  que representa el número de unidades a desplazar y un bit que indica el sentido del desplazamiento de la siguiente forma:

Bit 7=0 + dato(7bits):  Desplazamiento a la izquierda
Bit 7=1 +dato( 7bits):  Desplazamiento a la derecha

El movimiento del carro se realiza enviando al carro una cantidad de pulsos igual al valor recibido. Cada pulso a enviar será de 200ms en “0” y 50ms en “1” y se envían  por dos líneas de puertos (izquierda – derecha) según el sentido del movimiento. Cuando se están enviando pulsos por una línea la otra debe permanecer en alto.

El sistema dispone además de los siguientes elementos:
1-   Un sensor óptico de posición que detecta si el carro está fuera del carril y envía un pulso activo en “0” al procesador el cual será atendido por interrupción externa e implica que el procesador debe detener el movimiento del carro, llevando ambas líneas de control al estado de “1”.
2-   Una  tecla  origen  que  permite  al  oprimirse  regresar  el  carro  a  la  posición  inicial  enviando  al mismo por otra línea de puerto, una señal de reinicio  activa en “0”durante 50ms.
Realice el diseño completo del hardware y software del sistema. Utilice los TIMERS para todos los requerimientos de tiempo del sistema. Frec-reloj=8Mhz.*/
/*
Iniciar líneas en alto
INT 0 activo en 0
Leer puerto A
Enviar PWM 
cantidad de pulsos=dato
Leer INT1,activo en 0	Poner PWM en 1
Leer INT2,activo en 0, mandar 0 durante 50ms en otra línea.



*/

.INCLUDE "m16def.inc"
.ORG 0		;Reset
RJMP main
.ORG 0x2	;INT0
RJMP inicio	
.ORG 0x04	;INT1
RJMP sensorOptico	
.ORG 0x10	;TOV1 overflow
RJMP timer
.ORG 0x24	;INT2
RJMP reclaOrigen
.ORG 0x26	;Timer 0 Compare
RJMP retardo
main:
	;Pila
	LDI R16,HIGH(RAMEND)
	OUT SPH,R16
	LDI R16,LOW(RAMEND)
	OUT SPL,R16

	;Puertos
	SBI DDRD,4	;PWM OC1B izquierdo
	SBI DDRD,5	;PWM 0C1A derecha
	SBI DDRD,6	;Señal de reinicio

	;Valores iniciales a 1
	SBI PORTD,4
	SBI PORTD,5
	SBI PORTD,6 

	;Tope (Periodo)
	;f_pulso=1/(200ms+50ms)=4
	;Top=8M/4/1024-1=1952
	LDI R16,HIGH(1952);
	OUT ICR1H,R16
	LDI R16,LOW(1952)
	OUT ICR1L,R16

	;Compares(Duty Cycle)	Modo invertido para que envíe primero 0 200ms y luego 1 50ms
	;Top-(DutyCycle*Top)=1952-1952*0.2=1562  
	LDI R16,HIGH(1562)
	OUT OCR1AH,R16
	OUT OCR1BH,R16
	LDI R16,LOW(1562)
	OUT OCR1AL,R16 
	OUT OCR1BL,R16
	
	;Interrupciones
	LDI R16,0b11100000	;Habilitar INT0(inicio),INT1(limite),INT2(tecla)
	OUT GICR,R16  		
	LDI R16,0b00001010	;Detectar flanco de bajada para INT0 e INT1
	OUT MCUCR,R16
	LDI R16,0b00000000	;Detectar flanco de bajada para INT2
	OUT MCUCSR,R16
	LDI R16,0b00000110 ;TOIE1 Overflow de timer 1 y OCIE0 Compare de timer 0
	OUT TIMSK,R16
	SEI
	fin: 
		RJMP fin
;Interrupciones
inicio:
	IN R16,SREG
	PUSH R16
		
	IN R23,PINA
	MOV R22,R23
	ANDI R22,0b01111111	;Número de pulsos
	ANDI R23,0b10000000	;Bit de signo
	CPI R23,0
	BRNE derecha
	
	izquierda:	
		LDI R16,0b00110010	;Modo 14,Clear para OC1B
		OUT TCCR1A,R16
		LDI R16,0b00011101	;Modo 14,prescaler de 1024
		OUT TCCR1B,R16
		SBI PORTD,5	;derecha en 1
		RJMP inicioRETI

	derecha:
		LDI R16,0b11000010	;Modo 14,Clear para OC1A
		OUT TCCR1A,R16
		LDI R16,0b00011101	;Modo 14,prescaler de 1024
		OUT TCCR1B,R16
		SBI PORTD,4	;izquierda en 1
	inicioRETI:
		POP R16
		OUT SREG R16
		RETI

timer:
	IN R16,SREG
	PUSH R16

	INC R20	;Contador de pulsos
	CP R20,R22	;Comparar contador de pulsos y pulsos a enviar 
	BRLO timerRETI
	
	CLR R16
	OUT TCCR1B,R16 ;Apagar timer
	CLR R20	;Resetear contador de pulsos
	SBI PORTD,4
	SBI PORTD,5	

	timerRETI:

		POP R16
		OUT SREG,R16
		RETI	

sensorOptico:
	IN R16,SREG
	PUSH R16
	
	CLR R16 ;Dejar de mandar pulsos, apagar timer
	OUT TCCR1B,R16

	CLE R20	;Resetear contador de pulsos
	SBI PORTD,4
	SBI PORTD,5

	POP R16
	OUT SREG,R16
	RETI

teclaOrigen:
	IN R16,SREG
	PUSH R16
	
	CLR R16	;Apagar timer
	OUT TCCR1B,R16
	
	CLR R20	;Resetear contador de pulsos
	SBI PORTD,4
	SBI PORTD,5

	CBI PORTD,6	;Señal de reinicio en 0	

	;OCR0=25ms/125ns/1024-1=194
	LDI R16,194	;25ms
	OUT OCR0,R16
	LDI R16,0b0001101	;CTC, prescaler de 1024
	OUT TCCR0,R16
	LDI R21,2	;Contador de retardo
		
	POP R16
	OUT SREG,R16
	RETI

retardo:
	IN R16,SREG
	PUSH R16
	
	DEC R21	;Decrementar contador de retardo
	BRNE reiniciarRetardo

	terminarRetardo:
		SBI PORTD,6;
		CLR R16
		OUT TCCR0,R16
		CLR R21
		RJMP retardoRETI	
	reinicioRetardo:
		LDI R16,194	;25ms
		OUT OCR0,R16
		LDI R16,0b0001101	;CTC, prescaler de 1024
		OUT TCCR0,R16	
	retardoRETI:
		POP R16
		OUT SREG,R16
		RETI