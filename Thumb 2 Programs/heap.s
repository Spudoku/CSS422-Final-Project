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
		;MOV		R9, R5				; save midpoint
		PUSH	{R0-R7}
		SUB		R2, R5, R11			; new right = midpoint - mcb_ent_size
		BL		_ralloc
		MOV		R8, R0
		;MOV		
		POP		{R0-R7}
		
		CMP		R8, #0x0
		BEQ		_ralloc_try_right	; left failed, recurse right
		
		; left succeeded
		;MOV		R0, R8				; 
		B       _ralloc_left_good
		
_ralloc_try_right
		; goal: get left buddy I guess
		PUSH	{R1}
		MOV		R1, R5				; use saved midpoint
		BL		_ralloc
		POP		{R1}
		
		CMP		R0, #0
		BEQ		_ralloc_return_null	; both left and right failed
		; split parent!
		;if ((array[m2a(left)] & 0x01) == 0)
		;	*(short *)&array[m2a(left)] = act_half_size;
		LDRH		R9, [R1] 			; load MCB entry into R9

		AND			R9, R9, #0x01		; ; check allocation bit
		CMP			R9, #0
		BNE			_ralloc_return_heap_addr	
		; if allocation bit == 0
		; store ; 	R7: act_half_size
		STRH		R7, [R1]
		
		B		_ralloc_return_heap_addr	; right succeeded
_ralloc_left_good
		; split parent
		;if ((array[m2a(midpoint)] & 0x01) == 0)
		;	*(short *)&array[m2a(midpoint)] = act_half_size;

		LDRH		R9, [R5] 			; load MCB entry into R9
		MOV			R10, R9			; copy of arrray[m2a(midpoint)]

		AND			R10, R10, #0x01		; ; check allocation bit
		CMP			R10, #0
		BNE			_ralloc_return_heap_addr	
		; if allocation bit == 0
		; store ; 	R7: act_half_size
		STRH		R7, [R5]
		
		B			_ralloc_return_heap_addr	
_ralloc_base
		; check if left works
		; load (array[m2a(left)]) into R9
		; registers I CAN use: R7, R8 (MUST be overridden at the end) R9, R10, R11
		; values to keep (until heap address is calculated): m2a(left), array[m2a(left)]
		; keep in R10 and R11 respectively
		; R7-9 are disposable values
		;R1
		;int m2a(int sram_addr)
;{
  ;int index = sram_addr - 0x20000000;
  ;// printf( "m2a: sram_addr = %x array_index = %d\n", sram_addr, index );
  ;return index;
;}
		;(array[m2a(left)] & 0x01) != 0, return null
		; calculate offset, aka m2a(left)
		LDRH		R9, [R1]		; load half word at left (array[m2a(left)]
		MOV			R10, R9			; copy of array entry
		AND			R10, R10, #0x01	; check allocation bit
		CMP			R10, #1
		BEQ			_ralloc_return_null	; if allocated, return null
		
		; we have entire space
		MOV			R10, R9		; save another copy
		LDR			R11, =0xFFFE		; strip allocation bit
		AND			R11, R10, R11
		CMP			R10, R6				; compare mcb entry contents with act_entire_size
		BCC			_ralloc_return_null		;  if R10 < R6, return null
		
		; allocate block
		ORR			R9, R6, #0x01
		MOV			R8, R9
		STRH		R8, [R1]
		
		; compute heap address and return
		LDR			R7, =MCB_TOP		
		LDR			R8, =HEAP_TOP
		SUB			R7, R1, R7					; left - mcb_top

		LSL			R7, R7, #4					; multiply by 16
		ADD			R8, R8, R7
		B			_ralloc_return_heap_addr
		
;		return 0 (NULL)
_ralloc_return_null
		MOV     	R0, #0
		POP     	{pc}

;		return whatever's in R8
_ralloc_return_heap_addr
		MOV     	R0, R8
		POP     	{pc}

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
; Parameters: 
; 	R0: mcb_addr
; Local Variables:
;	R1: mcb_contents
;	R2: mcb_index
;	R3: mcb_disp
;	R4: my_size
;	R5: mcb_buddy_index (recursive cases)
;	R6: mcb_buddy_array = array[mcb_buddy_index]
_rfree
		PUSH	{lr}
		; calculating R1 (mcb_contents)
		LDRH	R1, [R0]		; array(mcb_addr)
		; clear used bit
		LDR		R11, =0xFFFE		; strip allocation bit
		AND		R1, R1, R11			
		STRH	R1, [R0]		; array(mcb_addr)
		
		; calculate mcb_index (R2)
		LDR		R11, =MCB_TOP
		SUB		R2, R0, R11		; mcb_index = mcb_addr - MCB_TOP
		; calculate mcb_disp (R3)
		MOV		R11, #16
		UDIV	R3, R1, R11		; mcb_disp = mcb_contents / 16
		; calculate my_size (R4)
		;LSL		R4, R1, #4		; my_size = mcb_contents * 16
		MOV		R4, R1
		
		;   if ((mcb_index / mcb_disp) % 2 == 0)
		; calculate mcb_index / mcb_disp into R5
		UDIV	R5, R2, R3
		; perform R5 % 2, storing result into R5
		LDR		R11, =0x0001		
		AND		R5, R5, R11			; basically check if R5's last bit = 1
		CMP		R5, #0
		BEQ		_rfree_left			; if ((mcb_index / mcb_disp) % 2 == 0), go left
		B		_rfree_right		; else go right
		; calculate mcb_buddy_index 
		; formula: mcb_buddy_index = mcb_addr + mcb_disp
_rfree_left
		; check mcb_addr + mcb_disp
		
		ADD		R5, R0, R3
		LDR		R7, =MCB_BOT
		CMP		R5, R7			; if mcb_addr + mcb_disp >= mcb_bot, return null
		; buddy would be outside of mcb array
		BCS		_rfree_return_null 
		
		; otherwise, continue
		; calculate mcb_buddy into R6
		LDRH	R6, [R5]
		; now compare mcb_buddy (R6)
		; store copy of R6 into R8
		MOV		R10, R6
		AND		R10, R10, #0x01			; check last bit
		CMP		R10, #1					; if R8 (after an AND) == 1, return mcb_addr
		BEQ		_rfree_return_mcb_addr 
		; clear last bits 4-0 of mcb_buddy
		; mask should be FFE0, for 1111 1111 1110 0000
		MOV		R10, R6
		LDR		R9, =0xFFE0
		AND		R10, R10, R9
		CMP		R10, R4
		BNE		_rfree_return_mcb_addr 		; return mcb addr; buddies are not the same size
		; otherwise continue
		; clear self
		; TODO: fix clearing and merging buddy
		MOV		R9, #0
		STRH	R9, [R5]				; *(short *)&array[m2a(mcb_addr + mcb_disp)] = 0; // clear my buddy
		LSL		R4, #1					; my_size * 2
		STRH	R4, [R0]				; *(short *)&array[m2a(mcb_addr)] = my_size; // merge my budyy
		
		POP		{lr}
		BL		_rfree				; recurse/promote myself or buddy!
		
		
_rfree_right
		SUB		R5, R0, R3
		LDR		R7, =MCB_TOP
		CMP		R5, R7			; if mcb_addr + mcb_disp < mcb_bot, return null
		; buddy would be outside of mcb array
		BCC		_rfree_return_null 
		; otherwise, continue
		; calculate mcb_buddy into R6
		LDRH	R6, [R5]
		; now compare mcb_buddy (R6)
		; store copy of R6 into R8
		MOV		R8, R6
		AND		R8, R8, #0x01			; check last bit
		CMP		R8, #1					; if R8 (after an AND) == 1, return mcb_addr
		BEQ		_rfree_return_mcb_addr 
		; clear last bits 4-0 of mcb_buddy
		; mask should be FFE0, for 1111 1111 1110 0000
		MOV		R8, R6
		LDR		R9, =0xFFE0
		AND		R8, R8, R9		; clear bits 4-0
		CMP		R8, R4
		BNE		_rfree_return_mcb_addr 		; return mcb addr; buddies are not the same size
		; otherwise continue
		; clear self
		; TODO: fix clearing and merging buddy
		MOV		R9, #0
		STRH	R9, [R0]				; *(short *)&array[m2a(mcb_addr)] = 0; // clear myself
		LSL		R4, #1					; my_size * 2
		STRH	R4, [R5]				; *(short *)&array[m2a(mcb_addr - mcb_disp)] = my_size; // merge me to my buddy
		
		MOV		R0, R5
		B		_rfree				; recurse/promote myself or buddy!

;_r_free_recurse
		
		
; return 0
_rfree_return_null 
		MOV		R0, #0
		POP		{pc}
		
; return mcb_addr
_rfree_return_mcb_addr 
		POP		{pc}


; void free( void *ptr )
		EXPORT	_kfree
_kfree
		PUSH	{lr}
		; validate ptr
		; shouldn't need to convert
		LDR		R1, =HEAP_TOP
		LDR		R2, =HEAP_BOT
		
		CMP		R0, R1			; if ptr < HEAP_TOP
		BCC		_kfree_return_null
		CMP		R0, R2			; if ptr > HEAP_BOT
		BHI		_kfree_return_null
		
		; 		otherwise, pointer is valid
		PUSH	{R0}			; store pointer for later
		SUB		R0, R0, R1		; R0 = addr - HEAP_TOP
		LDR		R3, =MCB_TOP
		MOV		R4, #16
		UDIV	R0, R0, R4		; (addr - HEAP_TOP) / 16
		ADD		R0, R0, R3		; MCB_TOP + (addr - HEAP_TOP) / 16
		BL		_rfree
		; check R0 (if _rfree(mcb_addr) == 0)
		CMP		R0, #0
		BEQ		_kfree_return_null
		
		
		B		_kfree_return_ptr


_kfree_return_null
		POP		{R0}
		MOV		R0, #0			; return null
		POP		{lr}
		BX		lr
		
_kfree_return_ptr
		POP		{R0}
		MOV		R0, R1
		POP		{lr}
		BX		lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
		END
			
			