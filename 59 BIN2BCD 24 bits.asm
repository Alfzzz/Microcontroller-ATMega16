.INCLUDE "m16def.inc"

.ORG 0
.DEF BIN0=R21
.def BIN1=R22
.def BIN2=R23

LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI BIN2,1
LDI BIN1,0x0E
LDI BIN0,0x1F
CALL BIN2BCD
	
fin:	
	RJMP fin

BIN2BCD: 
	CLR R16                  
	STS 0x60,R16                  
	STS 0x61,R16  
	STS 0x62,R16  	
	STS 0x63,R16    
	STS 0x64,R16
	STS 0x65,R16
	otroBIN:  
		CPI BIN0,0           
		BRNE INC_BCD           
		CPI BIN1,0           
		BRNE INC_BCD
		CPI BIN2,0
		BRNE INC_BCD           
		RET
	
		INC_BCD: 	
			LDI R17,0      	
			LDI YL,0x65    
			LDI YH,0     
			cicloINC_BCD: 
				LD R20,Y            
				INC R20            
				ST Y,R20            
				CPI R20,10            
				BRNE DEC_BIN           
				ST Y, R17            	
				DEC YL            
				CPI YL,0x5F            
				BRNE cicloINC_BCD
				
				DEC_BIN: 
					DEC BIN0         
					CPI BIN0,0xFF         
					BRNE otroBIN         
					DEC BIN1
					CPI BIN1,0xFF
					BRNE otroBIN
					DEC BIN2         
					RJMP otroBIN