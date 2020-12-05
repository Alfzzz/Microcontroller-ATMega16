;sumar 2 numeros de 16bits 0x101 0x100 + 0x201 0x200 = 0x301 0x300 (todo en SRAM)
.ORG ;Directiva de origen, donde empieza a guardar las instrucciones
.INCLUDE "m16def.inc" ;Definiciones del procesador, definir los registros, las banderas

LDS R16,0x100 ;guardar el contenido de la dirección de 0x100 en R16
LDS R17,0x200 ;guardar el contenido de la dirección de 0x200 en R17
LDS R18,0x101 ;guardar el contenido de la dirección de 0x101 en R18
LDS R19,0x201 ;guardar el contenido de la dirección de 0x201 en R19
ADD R16,R17 ;sumar R16 con R17
ADC R18,R19 ; sumar R18, R19 y el carry del resultado anterior
STS 0x300, R16 ;guardar el R16(Los 8 bits menos significativos de la suma) en la dirección de 0x300
STS 0x301, R18 ;guardar el R18(Los 8 bits más significativos de la suma)  en la dirección de 0x301
