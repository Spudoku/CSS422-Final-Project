		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
; in driver_keil.c: R0 = 0x2000583C - 0x20005864
; in 
		EXPORT	_bzero
_bzero
					; implement your complete logic, including stack operations
					; R0 should be *s, R1 should be n
					; for loop?
					STMFD sp!, {r1-r12,lr}	; stores registers and link register onto stack
					CMP		R1, #0
					BEQ		_bezero_end
					MOV		R2, #0			; for int R2 = 0
					ADD		R1, R0, R1		; R1 = R1 + R0
		
for_loop			CMP		R0, R1			; R2 < R1
					BEQ		_bezero_end		
					MOV		R3, #0
					STRB	R3, [R0], #1
					B		for_loop
_bezero_end			
					LDMFD sp!, {r1-r12,lr}	; load registers and link register from stack
					MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
			; R0: dest
			; R1: src
			; R2: size
_strncpy
		; implement your complete logic, including stack operations
					STMFD sp!, {r1-r12,lr}	; stores registers and link register onto stack
					LDRB	R3, [R1]			; load 
					MOV		R4,	#0				; counter
					MOV		R5, R0				; store original dest
while_loop			CMP		R3, #0				; if null byte found, return
					BEQ		done
					CMP		R4, R2				; if R4 == size, return
					BEQ		done
					
					LDRB	R3, [R1], #1
					STRB	R3, [R0], #1
					ADD		R4, R4, #1
					B while_loop
done
					MOV		R0, R5				; R0 = original dest (return value)
					LDMFD sp!, {r1-r12,lr}	; load registers and link register from stack
					MOV		pc, lr				; return to main
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		;STMFD 	sp!, {r1-r12,lr}	; stores registers and link register onto stack
		; set the system call # to R7
		MOV		R7, #0x4
	    SVC     #0x0
		MOV		R0, R4
		;LDMFD sp!, {r1-r12,lr}	; load registers and link register from stack
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		STMFD sp!, {r1-r12,lr}	; stores registers and link register onto stack
		; set the system call # to R7
		MOV		R7, #0x5
	    SVC     #0x0
		LDMFD sp!, {r1-r12,lr}	; load registers and link register from stack
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		STMFD sp!, {r1-r12,lr}	; stores registers and link register onto stack
		; set the system call # to R7
        MOV		R7, #0x1
	    SVC     #0x0
		LDMFD sp!, {r1-r12,lr}	; load registers and link register from stack
		MOV		pc, lr		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		STMFD sp!, {r1-r12,lr}	; stores registers and link register onto stack
		; set the system call # to R7
        MOV		R7, #0x2
	    SVC     #0x0
		LDMFD sp!, {r1-r12,lr}	; load registers and link register from stack
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
