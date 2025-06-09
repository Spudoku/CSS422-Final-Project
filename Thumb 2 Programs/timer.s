		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
	; stop SysTick:
		; set SYST_CSR bits:
		; bit 2 (CLK_SRC) = 1
		; bit 1 (INT_EN) = 0
		; bit 0 (ENABLE) = 0
		LDR		R1, =0xE000E010	; SYST_CSR
		LDR		R2, [R1]
		ORR		R2, R2, #0x0004			; set bit 2 to 1
		AND		R2, R2, #0xEC			; set bits 1 and 0 to 0
		STR		R2, [R1]
		
		; load maximum into SYS_RVR
		LDR		R1, =0xE000E014	; SYST_RVR
		LDR		R2, =STRELOAD_MX
		STR		R2, [R1]
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
		;; Implement by yourself
		
		
		MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
; R0 = STCTRL
; R1 = STCTRL_STOP
; R2 = SECOND_LEFT
; R3 = USR_HANDLER
_timer_update
		LDR r3, =SECOND_LEFT ; retrieve seconds left
		LDR r0, [r3]
		SUB r0, r0, #1 ; decrement seconds
		STR r0, [r3] ; save seconds left
		CMP r0, #0
		BNE _timer_update_done ; if seconds still remain, don't stop SysTick
		LDR r3, =STCTRL ; Stop SysTick
		MOV r4, #STCTRL_STOP
		STR r4, [r3]
		; invoke a user-provided signal handler
		MOVS R0, #3 ; Set SPSEL bit 1, nPriv bit 0
		MSR CONTROL, R0 ; Now thread mode uses PSP for user
		LDR r3, =USR_HANDLER ; call a user-provided handler
		LDR r4,[r3]
		BX r4 ; Invoke the handler (r0)
_timer_update_done
		MOV pc, lr ; return to SysTick_Handler


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
	
		MOV		pc, lr		; return to Reset_Handler
		
		END		
