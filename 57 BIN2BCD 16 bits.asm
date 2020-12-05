.INCLUDE "m16def.inc"

.ORG 0
.def BIN_LSB=R22
.def BIN_MSB=R23

LDI R16,LOW(RAMEND)
OUT SPL,R16
LDI R16,HIGH(RAMEND)
OUT SPH,R16

CALL BIN2BCD
	
fin:	
	RJMP fin

BIN2BCD: 
	CLR R16                  
	STS 0x60,R16                  
	STS 0x61,R16  
	STS 0x62,R16  	
	STS 0x63,R16    
	otroBIN:  
		CPI BIN_LSB,0           
		BRNE INC_BCD           
		CPI BIN_MSB,0           
		BRNE INC_BCD           
		RET
	
		INC_BCD: 	
			LDI R17,0      	
			LDI YL,0x63      
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
					DEC BIN_LSB         
					CPI BIN_LSB,0xFF         
					BRNE otroBIN         
					DEC BIN_MSB         
					RJMP otroBIN