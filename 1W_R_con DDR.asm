;Realice un programa que lea el puerto A y escribe su valor en el puerto C
LDI R16, 0x00 ; Guardar 0 en R16
OUT DDRA, R16 ; Configurar puerto A como entrada
LDI R16, 0XFF ; Guardar FF en R16
OUT DDRC, R16 ; Configurar puerto C como salida
IN R16, PINA    ; Leer puerto A y guardarlo en R16
OUT PORTC, R16  ; Escribe en puerto C lo que hay en R16
