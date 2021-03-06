/**
 * AS - the open source Automotive Software on https://github.com/parai
 *
 * Copyright (C) 2017  AS <parai@foxmail.com>
 *
 * This source code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published by the
 * Free Software Foundation; See <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 */
.extern __bss_start
.extern __bss_end
.extern main

.macro DEFAULT_ISR_HANDLER name=
  .section .text
  .weak \name
\name:
  b \name /* endless loop */
.endm

	.section .init
	.globl _start
;;
_start:
    ldr     pc, reset_handler
    ldr     pc, _vector_undef
    ldr     pc, _vector_swi
    ldr     pc, _vector_pabt
    ldr     pc, _vector_dabt
    ldr     pc, _vector_resv
    ldr     pc, _vector_irq
    ldr     pc, _vector_fiq

reset_handler:  .word reset
_vector_undef:  .word vector_undef
_vector_swi:    .word vector_swi
_vector_pabt:   .word vector_pabt
_vector_dabt:   .word vector_dabt
_vector_resv:   .word vector_resv
_vector_irq:    .word vector_irq
_vector_fiq:    .word vector_fiq

reset:
	;@	In the reset handler, we need to copy our interrupt vector table to 0x0000, its currently at 0x8000

	mov r0,#0x8000								;@ Store the source pointer
    mov r1,#0x0000								;@ Store the destination pointer.

	;@	Here we copy the branching instructions
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Load multiple values from indexed address. 		; Auto-increment R0
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Store multiple values from the indexed address.	; Auto-increment R1

	;@	So the branches get the correct address we also need to copy our vector table!
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Load from 4*n of regs (8) as R0 is now incremented.
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Store this extra set of data.


	;@	Set up the various STACK pointers for different CPU modes
    ;@ (PSR_IRQ_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD2
    msr cpsr_c,r0
    mov sp,#0x8000

    ;@ (PSR_FIQ_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD1
    msr cpsr_c,r0
    mov sp,#0x6000

    ;@ (PSR_SVC_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD3
    msr cpsr_c,r0
	mov sp,#0x4000

    ;@ (PSR_SYS_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xDF
    msr cpsr_c,r0
	mov sp,#0x2000

	ldr r0, =__bss_start
	ldr r1, =__bss_end

	mov r2, #0

zero_loop:
	cmp 	r0,r1
	it		lt
	strlt	r2,[r0], #4
	blt		zero_loop

	bl 		DisableInterrupts   ;@  to be modified

	;@ 	mov	sp,#0x1000000
	b main									;@ We're ready?? Lets start main execution!
	b .

DEFAULT_ISR_HANDLER vector_undef
DEFAULT_ISR_HANDLER vector_swi
DEFAULT_ISR_HANDLER vector_pabt
DEFAULT_ISR_HANDLER vector_dabt
DEFAULT_ISR_HANDLER vector_resv
DEFAULT_ISR_HANDLER vector_irq
DEFAULT_ISR_HANDLER vector_fiq


	.section .text
    .global Irq_Restore
    .type   Irq_Restore, %function
/* void Irq_Restore( imask_t intsts ); */
Irq_Restore:
    msr cpsr, r0
    mov pc, lr

    .global __Irq_Save
    .type   __Irq_Save, %function
/* imask_t __Irq_Save( void ); */
__Irq_Save:
    mrs r0, cpsr
    orr r1, r0, #0xc0
    msr cpsr_c, r1
    mov pc, lr


/* void Irq_Disable(void)   */
    .global Irq_Disable
    .type   Irq_Disable, %function
Irq_Disable:
    mrs r0, cpsr
    orr r0, r0, #0xc0
    msr cpsr_c, r0
    mov pc, lr

/* void Irq_Enable(void) */
    .global Irq_Enable
    .type   Irq_Enable, %function
Irq_Enable:
    mrs r0, cpsr
    bic r0, r0, #0xc0
    msr cpsr_c, r0
    mov pc, lr
