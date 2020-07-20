;简单版本
.386
DATA 	SEGMENT USE16
	MESG    DB 'I WILL STOP ONCE PRESSED',0AH,0DH,'$'
	ICOUNT1 DB 100;100*5ms=0.5s
	ICOUNT2 DB 11;11*5ms=55ms
	OLD08   DD ?;用于保存原来的08H服务程序地址
DATA ENDS
CODE	SEGMENT USE16
	ASSUME CS:CODE,DS:DATA
BEG:	MOV AX,DATA
		MOV DS,AX
		CLI			;关中断
		CALL I8254		
		CALL READ08		
		CALL WRITE08	
		STI			;开中断
SCAN:	MOV AH,1
        INT 16H
        JZ SCAN
RETURN:	CLI
		CALL RESET
		STI
		MOV AH,4CH
		INT 21H	
;----
SERVICE	PROC
		PUSHA
		PUSH DS
FIRST:	DEC ICOUNT1
		JNZ NEXT
		MOV AH,9
		LEA DX,MESG
		INT 21H
		MOV ICOUNT1,200
NEXT:	DEC ICOUNT2
		JNZ EXIT		
		MOV ICOUNT2,11	
		POP DS
		POPA
		JMP OLD08
EXIT:   MOV AL,20H
		OUT 20H,AL
		POP DS
		POPA
		IRET
SERVICE ENDP
READ08  PROC;读取原中断程序地址
		MOV AX,3508H
		INT 21H
		MOV WORD PTR OLD08,BX
		MOV WORD PTR OLD08+2,ES
		RET
	READ08 ENDP
WRITE08 PROC;写新的中断程序地址
		PUSH DS
		MOV  AX,CODE
		MOV  DS,AX
		LEA  DX,SERVICE
		MOV  AX,2508H
		INT 21H
		POP DS
		RET
	WRITE08 ENDP
I8254	PROC;调整计数器设置
		MOV AL,00100110B		;00为0号计数器|11为3号读写方式|011为3号工作方式|0使用初始值为二进制数
		OUT 43H,AL
		MOV AX,5966				;计数初值 = fclk / fout fclk=1.193182 MHZ fout=200Hz
		OUT 40H,AL
		MOV AL,AH
		OUT 40H,AL
		RET
	I8254 ENDP
RESET PROC
	MOV DX,WORD PTR OLD08
	MOV DS,WORD PTR OLD08+2
	MOV AX,2508H
	INT 21H
	RET
RESET ENDP
CODE ENDS
END BEG