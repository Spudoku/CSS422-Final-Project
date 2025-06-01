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
		LDR R1, =MCB_TOP
		
		LDR R2, =MCB_BOT
		LDR	R3, =MAX_SIZE
		STR	R3, [R1]
		ADD	R1, R1, #4
		; zero out the MCB array
		MOV	R4, #0x00
_heap_init_loop
		CMP	R1, R2
		BCS	_heap_init_done		; if R1 >= R2
		STR	R4, [R1]
		;STR R4, [R1, #1]
		ADD	R1, R1, #2			; R1 += 2
		B	_heap_init_loop
_heap_init_done
		MOV		pc, lr
		


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; TODO: _ralloc
; Parameters:
; R0: size
; R1: left
; R2: right

; local variables:
; R3: entire
; R4: half
; R5: midpoint
; R6: act_entire_size
; R7: act_half_size
; R8: heap_addr
; R0 through R7 are reserved, EXCEPT when returning a pointer in R0!
; Store addresses in R8 when possible
		
_ralloc
		PUSH	{lr}		; store link register
		; defining entire
		SUB		R3, R2, R1; int entire = right - left  + mcb_ent_sz;
		LDR		R4, =MCB_ENT_SZ	
		ADD		R3, R3, R4
		
		; defining half
		MOV		R5, #2
		UDIV 	R4, R3, R5		; int half = entire / 2;
		
		; defining midpoint
		ADD		R5, R1, R4		; int midpoint = left + half;

		; definining act_entire_size
		LSL		R6, R3, #4 	; int act_entire_size = entire * 16;
		
		; defining act_half_size
		LSL		R7, R4, #4 	; int act_half_size = half * 16;
		; defining heap_addr
		MOV		R8, #0x0; 	int heap_addr = NULL;
		
		; if size > act_half_size, go to base case(s)
		CMP		R12, R7
		
		BHI		_ralloc_base
		; else recurse left
		PUSH	{R1-R7}		; store all variables
		; compute midpoint - mcb_ent_sz
		LDR		R9, =MCB_ENT_SZ
		SUB		R2, R5, R9 	;midpoint - mcb_ent_sz 
		BL		_ralloc
		MOV		R8, R0		; store result into R8
		POP		{R1-R7}
		CMP		R8, #0x0	; if heap_addr != NULL
		BNE		_ralloc_left_good
		; recurse right
		; left = midpoint
		MOV		R1, R5
		BL		_ralloc
		MOV		R8, R0		; store result into R8
		B		_ralloc_return_heap_addr
_ralloc_left_good
		; split parent
		B	_ralloc_return_heap_addr
_ralloc_base	; TODO: fix base case
		; load (array[m2a(left)]) into R9
		SUB		R9, R1, #0x20000000		; M2A left
		LDR		R10, =MCB_TOP			; array start
		LDR		R9, [R10, R9]			; array[m2a[left] = array_start + m2a(left)
		; test if memory block is used
		; if ((array[m2a(left)] & 0x01) != 0)
		; perform bitwise AND on R9
		MOV		R10, R9					; save array[m2a(left)] for later
		AND		R9, #0x01
		CMP		R9, #0x0
		BEQ		_ralloc_return_null
		; here we should have an entire space
		
		CMP		R9, R6 				; *(short *)&array[m2a(left)] < act_entire_size TODO: WHAT DOES THIS ACTUALLY DO
								
		BCC		_ralloc_return_null		; return null because it can't fit
		ORR		R6, #0x01				; otherwise, set allocated bit to 1
		; calculate return value as R8
		LDR		R10, =MCB_TOP			; array start
		LDR		R8, =HEAP_TOP			; heap start
		
		SUB		R11, R1, R10			;(left - mcb_top)
		ADD		R8, R8, R11, LSL  #4
		STRH	R6, [R10]				; store half word at address R6
		B		_ralloc_return_heap_addr ; return (void *)(heap_top + (left - mcb_top) * 16);
			
		;
_ralloc_return_null
		MOV		R0, #0x0
		POP		{pc}
		
_ralloc_return_heap_addr
		MOV		R0, R8
		POP		{pc}		; push a link register into the program counter
		;BX		lr
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
		MOV		R12, R0
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
			
			