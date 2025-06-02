		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
SRAM_START	EQU		0x20000000	; start of SRAM
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
		; mark the entire heap as a single unallocated block of memory
		; MCB[mcb_top - SRAM_START] = MAX_SIZE
		LDR 	R1, =MCB_TOP
		
		LDR 	R2, =MCB_BOT
		LDR		R3, =MAX_SIZE
		STRH	R3, [R1]
		ADD		R1, R1, #2
		; zero out the MCB array
		MOV		R4, #0x00
_heap_init_loop
		CMP		R1, R2
		BCS		_heap_init_done		; if R1 >= R2
		STRH	R4, [R1]
		;STR R4, [R1, #1]
		ADD		R1, R1, #2			; R1 += 2
		B		_heap_init_loop
_heap_init_done
		MOV		pc, lr
		


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; TODO: _ralloc
; Parameters:
; R1: left
; R2: right
; R12: size

; LOCAL VARIABLES
;	R3: entire
;	R4: half
;	R5: midpoint
;	R7: act_half_size
_ralloc
		PUSH	{lr}		; store link register
		; put entire into R3
		SUB		R3, R2, R1
		LDR		R4, =MCB_ENT_SZ
		LDR		R4, [R4]			; load value of =MCB_ENT_SZ with literal pool
		ADD		R3, R3, R4			; int entire = right - left  + mcb_ent_sz;
		
		; compute half into R4
		MOV		R5, #2
		UDIV	R4, R3, R5			; int half = entire / 2;
		
		; compute midpoint into R5
		ADD		R5, R1, R4			; int midpoint = left + half;
		
		; compute act_entire_size into R6
		LSL		R6, R3, #4
		
		; compute act_half_size into R7
		LSL		R7, R4, #4			; int act_half_size = half * 16;
		MOV		R0, #0x23		; set heap_addr to null
		; 
		
		POP		{pc}
		; END _ralloc


; void* _k_alloc( int size )
		EXPORT	_kalloc
			; parameters:
			; R0 = int size
_kalloc
	; set up parameters for _ralloc
	; R0 = size (same as passed in parameter)
	; R1 = MCB_TOP
	; R2 = MCB_BOT
		PUSH	{lr}
		LDR		R1, =MCB_TOP
		LDR		R2, =MCB_BOT
		MOV		R12, R0			; store size in R12
		
		BL		_ralloc
		POP		{lr}
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; TODO: _rfree
; 
_rfree
		
		MOV		pc, lr

; void free( void *ptr )
		EXPORT	_kfree
_kfree
	;; Implement by yourself
	; validate address
	
	; compute MCB address
	
	; invoke _rfree
		MOV		pc, lr					; return from rfree( )
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		END
			
			