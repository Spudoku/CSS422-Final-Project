		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

		IMPORT	_kfree
		IMPORT	_kalloc
		IMPORT	_signal_handler
		IMPORT	_timer_start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
		; _timer_start / SYS_ALARM
		LDR		R0, =_timer_start
		LDR		R1, =SYSTEMCALLTBL
		MOV		R2, #SYS_ALARM
		STR		R0, [R1, R2, LSL #2]	; store at SYSTEMCALLTBL + SYS_ALARM * 4
		
		; _signal_handler / SYS_SIGNAL
		LDR		R0, =_signal_handler
		LDR		R1, =SYSTEMCALLTBL
		MOV		R2, #SYS_SIGNAL
		STR		R0, [R1, R2, LSL #2]	; store at SYSTEMCALLTBL + SYS_SIGNAL * 4
		
		; _kalloc / SYS_MALLOC
		LDR		R0, =_kalloc
		LDR		R1, =SYSTEMCALLTBL
		MOV		R2, #SYS_MALLOC
		STR		R0, [R1, R2, LSL #2]	; store at SYSTEMCALLTBL + SYS_MALLOC * 4
		
		; _kfree / SYS_FREE
		LDR		R0, =_kfree
		LDR		R1, =SYSTEMCALLTBL
		MOV		R2, #SYS_FREE
		STR		R0, [R1, R2, LSL #2]	; store at SYSTEMCALLTBL + SYS_FREE * 4

		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
	;; Implement by yourself
		
		LSL 	R7, R7, #2		; multiply R7 (SVC call #) by 4
		LDR 	R8, =SYSTEMCALLTBL	; load system call table
		LDR		R9, [R8, R7]	; apply offset to table
		BX		R9				; call routine
		MOV		pc, lr			
		
		END


		
