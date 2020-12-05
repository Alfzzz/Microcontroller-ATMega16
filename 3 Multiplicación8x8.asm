; Multiplicación de 0x200 x 0x201=0x301 0x300
LDS R16,0x200 ;Guardar el contenido de 0x200 a R16
LDS R17,0x201 ;Guardar el contenido de 0x201 a R17
MUL R16,R17 ; multiplicación de R16xR17
STS 0x301,R1 ;Guardar la parte más significativa del resultado en 0x301
STS 0x300,R0 ;Guardar la parte menos significativa del resultado en 0x300
 