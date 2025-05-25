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
		MOV	R4, #3
_heap_init_loop
		CMP	R1, R2
		BCS	_heap_init_done		; if R1 >= R2
		; zero stuff out I guess?
		
		STR	R4, [R1]
		ADD	R1, R1, #2			; R1 += 2
_heap_init_done
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	;; Implement by yourself
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
	;; Implement by yourself
		MOV		pc, lr					; return from rfree( )
		
		; TODO: m2a and a2m
		; R0 = SRAM_ADDR
_m2a
		PUSH	{LR}

		POP		{LR}
		; R0 = array_index (in MCB)
_a2m
		PUSH	{LR}

		POP		{LR}
		END
			
			