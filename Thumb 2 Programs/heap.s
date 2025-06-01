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
; R12: size
; R1: left
; R2: right

; local variables:
;	R3: entire
;	R4: half
;	R5: midpoint
;	R6: act_entire_size
; 	R7: act_half_size
;	R8: heap_addr
; Store addresses in R0 when possible
		
_ralloc
		PUSH	{lr}		; store link register
		MOV		R8, #0x0			; heap_addr = null
		LDR		R11, =MCB_ENT_SZ	; loading mcb_ent_sz
		; Calculate entire into R3
		SUB		R3, R2, R1			; right - left
		ADD		R3, R3, R11			; right - left + mcb_ent_size
		; Calculate half into R4
		MOV		R10, #2
		UDIV	R4, R3, R10			; half = entire / 2
		; calculate midpoint into R5
		ADD		R5, R1, R4				; midpoint = left + half
		; calculate act_entire_size into R6
		LSL		R6, R3, #4			; act_entire_size = entire * 16
		; calculate act_half_size into R7
		LSL		R7, R4, #4			; act_half_size = half * 16
		CMP		R12, R7				; compare size, act_half_size
		BLS		_ralloc_recurse		; if size <= act_half_size, recursive case

		B		_ralloc_base		; else: base case
_ralloc_recurse
		MOV		R9, R5				; save midpoint
		PUSH	{R0-R7}
		SUB		R2, R5, R11			; new right = midpoint - mcb_ent_size
		BL		_ralloc
		MOV		R8, R0
		;MOV		
		POP		{R0-R7}
		
		CMP		R8, #0x0
		BNE		_ralloc_left_good
		; else, recurse right
		; R1 = midpoint

		MOV		R1, R9				; use saved midpoint
		BL		_ralloc
		B		_ralloc_return_heap_addr
_ralloc_left_good
		; split parent
		; TODO: calculate m2a midpoint
		;if ((array[m2a(midpoint)] & 0x01) == 0)
		;	*(short *)&array[m2a(midpoint)] = act_half_size;
		LDR		R7, =MCB_TOP
		SUB		R10, R5, R7					; m2a(midpoint) = midpoint - mcb_top
		LDRH	R11, [R7,R10]				; array[m2a[midpoint] = array_start + m2a(midpoint)
		AND		R11, R11, #0x01
		CMP		R11, #0
		BNE		_ralloc_return_heap_addr	
		;		*(short *)&array[m2a(midpoint)] = act_half_size;
		MOV		R11, R6
		STRH	R11, [R7, R10]
		B		_ralloc_return_heap_addr	
_ralloc_base
		; check if left works
		; load (array[m2a(left)]) into R9
		; registers I CAN use: R7, R8 (MUST be overridden at the end) R9, R10, R11
		; values to keep (until heap address is calculated): m2a(left), array[m2a(left)]
		; keep in R10 and R11 respectively
		; R7-9 are disposable values
		
		LDR		R7, =MCB_TOP
		;SUB		R10, R1, R7					; m2a(left) = left - mcb_top
		SUB     R10, R1, R7     ; index = left - mcb_top
		LSL     R10, R10, #1    ; m2a(left): offset = index * 2
		;LDRH    R11, [R7, R10]  ; read array[m2a[left]]
		LDRH	R11, [R7,R10]				; array[m2a[left] = array_start + m2a(left)
		
		MOV		R8, R11						; save copy of R11 for comparisons				; TODO: why is R8 0?
		AND		R8, #0x01					; check MCB entry for allocation
		CMP		R8, #0x0
		BNE		_ralloc_return_null
		; otherwise, we have the entire space
		; if *(short *)&array[m2a(left)] < act_entire_size, return null
		MOV     R8, R11
		LDR		R9, =0xFFFE		
		AND     R8, R11, R9       ; Strip allocation bit

		CMP     R8, R6
		BCC		_ralloc_return_null
		; otherwise, allocate block 
		ORR R11, R11, #0x01     			; R11 |= 1
		STRH	R11, [R7,R10]	
		; compute heap address and return
		LDR     R8, =0x20001000				; heap top

		SUB		R9, R1, R7					; left - mcb_top
		LSL		R9, R9, #4
		ADD		R8, R8, R9
		
		B		_ralloc_return_heap_addr
_ralloc_return_null
		MOV     R0, #0
		POP     {pc}

_ralloc_return_heap_addr
		MOV     R0, R8
		POP     {pc}

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
			
			