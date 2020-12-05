.include "m16def.inc"
.org 0
.def BIN_LSB=R22
.def BIN_MSB=R23
ldi r16,low(RAMEND)
out SPL,r16
ldi r16,high(RAMEND)
out SPH,r16     ;init Stack PointerCALL BCD_BINARIO

CALL BCD2BIN
fin:
	RJMP fin

BCD2BIN:
	LDS R20,0x63     ; Pasar dato a convertir de RAM de display a 0x70 a 0x73
	STS 0x73,R20
	LDS R20,0x62
	STS 0x72,R20
	LDS R20,0x61
	STS 0x71,R20
	LDS R20,0x60
	STS 0x70,R20
	otroBCD:  
		LDS R20,0x73          ;Terminar cuando BCD=0         
		CPI R20,0         
		BRNE DEC_BCD         
		LDS R20,0x72         
		CPI R20,0         
		BRNE DEC_BCD         
		LDS R20,0x71         
		CPI R20,0         
		BRNE DEC_BCD          
		LDS R20,0x70          
		CPI R20,0          
		BRNE DEC_BCD          
		RET
			
		DEC_BCD: 
			LDI R17,9         ; Decrementar BCD     
			LDI YL,0x73     
			LDI YH,0
			ciclo: 
				LD R20,Y             
				DEC R20             
				ST Y,R20             
				CPI R20,0xFF              
				BRNE INC_BIN              
				ST Y, R17               
				DEC YL               
				CPI YL,0x6F	;Checar para 4 dígitos
				BRNE ciclo
				INC_BIN: 
					INC BIN_LSB        ; Incrementar binario 
					CPI BIN_LSB,0  
					BRNE otroBCD   
					INC BIN_MSB   
					RJMP otroBCD