; This file is part of the Underwater Runins Diamon  Escape.
; This macro This macro handles  a column in the game by  checking  
;each of  the  5 columns,  the second part  also operate  on  a row instead 
;of column by checking  if  a row is set.
; NOTE: this macro modifies: R22, R23

.MACRO GameCol 
	SBI PORTB, 3
	SBRS R27, @0
	SBI PINB, 3			    	
	SBI PORTB,5   	
	CBI PORTB,5
.ENDMACRO


.MACRO GameRow 
		SBI PORTB, 3
		SBRS R23, @0
		SBI PINB, 3			    	
		SBI PORTB,5   	
		CBI PORTB,5
.ENDMACRO
