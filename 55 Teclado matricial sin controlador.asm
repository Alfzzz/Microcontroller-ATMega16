.INCLUDE "m16def.inc"
.ORG 0    
RJMP main

main:
	;Pila
	LDI R16,HIGH(RAMEND)    
	OUT SPH,R16    
	LDI R16,LOW(RAMEND)    
	OUT SPL,R16  

	;Puertos  
	LDI R16,0x0F    
	OUT DDRC,R16         ; PC0-PC3 (salidas)PC4-PC7 (entradas)    
	CALL teclado ;Acción a realizar con el valor que devuelve teclado




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
			CPI R16,0xF0        
			BRNE tecladoColumna                  
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