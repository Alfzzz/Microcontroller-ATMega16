/*2-)  Un  sistema    basado  en  ATmega16  debe  monitorear  una  señal  proveniente  de  un  sistema  de instrumentación. La señal es de 8 bits y se deberán obtener 250 muestras de la señal cada 5seg cada una y almacenarlos en memoria  SRAM. El sistema dispone de las siguientes teclas de comandos
 INICIO: Se debe iniciar la medición y almacenamiento de las muestras. Al finalizar la captura se debe encender un led de aviso al usuario.
VALIDACIÓN: En esta opción el sistema debe comparar las muestras de la señal adquirida con un patrón de 8 bits almacenado en ROM en la dirección 200h. Si el 80% o más de las muestras adquiridas es mayor o igual que el patrón se debe enviar una señal de validación activa en “0” a una computadora central. Esta señal debe tener una duración de 50ms.De  lo  contrario  se  debe  activar  un  buzzer  durante  5seg.  En  cualquier  caso  el  sistema  debe  quedar listo para una nueva medición.
1Realice el diseño completo del Hardware del sistema. 2Realice el diseño completo del software. Utilice la rutina de retardo de 10ms para  TODOS los requerimientos de tiempo del sistema. (frec_reloj=8Mhz).
*/
.ORG 0
.INCLUDE "m16def.inc"

;Stack Pointer
LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

;Puertos Tecla de inicio PA0, LED PA1, PA2 tecla de validación, PA3 salida de computadora, PA4 buzzer, PB lectura de señal
LDI R16,0b00011010
OUT DDRA,R16

SBI PORTA,3 ;Computadora activa en 0, 1 predeterminado

PollingInicio:
	SBIC PINA,0
	RJMP PollingInicio
CALL retardo10ms
SBIC PINA,0
RJMP PollingInicio	;Tomar valor para ver si fue ruido
WaitInicio:
	SBIS PINA,0
	RJMP WaitInicio	;Esperar a que se suelte
CALL retardo10ms

LDI XH,HIGH(0x60)
LDI XL,LOW(0x60)

LDI R16,250	;Se deben hacer 500 muestras
LeerSeñal:
	IN R17, PINB
	ST X+,R17
	CALL retardo5s
	DEC R16
	BRNE LeerSeñal
SBI PORTA,1

PollingValidación:
	SBIC PINA,2
	RJMP PollingValidación
CALL retardo10ms
SBIC PINA,2
RJMP PollingValidación	;Tomar valor para ver si fue ruido
WaitValidación:
	SBIS PINA,2
	RJMP WaitValidación	;Esperar a que se suelte
CALL retardo10ms	

LDI ZH,HIGH(0x200<<1)
LDI ZL,LOW(0x200<<1)
LPM R16,Z

LDI R17,250	;250 lecturas
LDI R18,0	;Contador
LDI XL,LOW(0x60)
LDI XH,HIGH(0x60)
Comparación:
	LD R19,X+
	CP R19,R16
	BRHI MayorOIgual
	DEC R17
	BRNE Comparación
CPI R18,200
BRHI SeñalValidación
BRLO Buzzer
RJMP PollingInicio

Buzzer:
	SBI PORTA,4
	CALL retardo5s
	CBI PORTA,4
RET

SeñalValidación:
	CBI PORTA,3
	CALL retardo50ms
	SBI PORTA,3
RET

MayorOIgual:
	INC R18
RET

retardo50ms:
	LDI R24,5
	ciclo5:
		CALL retardo10ms
		DEC R24
		BRNE ciclo5
RET

retardo5s:
	LDI R22,2
	ciclo3:
		LDI R23,250	
	ciclo4:
		CALL retardo10ms
		DEC R23
		BRNE ciclo4
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