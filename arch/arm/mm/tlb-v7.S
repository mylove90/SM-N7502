/*
 *  linux/arch/arm/mm/tlb-v7.S
 *
 *  Copyright (C) 1997-2002 Russell King
 *  Modified for ARMv7 by Catalin Marinas
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 *  ARM architecture version 6 TLB handling functions.
 *  These assume a split I/D TLB.
 */
#include <linux/init.h>
#include <linux/linkage.h>
#include <asm/assembler.h>
#include <asm/asm-offsets.h>
#include <asm/page.h>
#include <asm/tlbflush.h>
#include "proc-macros.S"

/*
 *	v7wbi_flush_user_tlb_range(start, end, vma)
 *
 *	Invalidate a range of TLB entries in the specified address space.
 *
 *	- start - start address (may not be aligned)
 *	- end   - end address (exclusive, may not be aligned)
 *	- vma   - vma_struct describing address range
 *
 *	It is assumed that:
 *	- the "Invalidate single entry" instruction will invalidate
 *	  both the I and the D TLBs on Harvard-style TLBs
 */
ENTRY(v7wbi_flush_user_tlb_range)
	vma_vm_mm r3, r2			@ get vma->vm_mm
	mmid	r3, r3				@ get vm_mm->context.id
	dsb
	mov	r0, r0, lsr #PAGE_SHIFT		@ align address
	mov	r1, r1, lsr #PAGE_SHIFT
#ifdef CONFIG_ARCH_MSM8X60
	mov	r0, r0, lsl #PAGE_SHIFT
#else
	asid	r3, r3				@ mask ASID
#ifdef CONFIG_ARM_ERRATA_720789
	ALT_SMP(W(mov)	r3, #0	)
	ALT_UP(W(nop)		)
#endif
	orr	r0, r3, r0, lsl #PAGE_SHIFT	@ Create initial MVA
#endif
	mov	r1, r1, lsl #PAGE_SHIFT
1:
#if defined(CONFIG_ARCH_MSM8X60) || defined (CONFIG_ARM_ERRATA_720789)
	ALT_SMP(mcr	p15, 0, r0, c8, c3, 3)	@ TLB invalidate U MVA (shareable)
#else
	ALT_SMP(mcr	p15, 0, r0, c8, c3, 1)	@ TLB invalidate U MVA (shareable)
#endif
	ALT_UP(mcr	p15, 0, r0, c8, c7, 1)	@ TLB invalidate U MVA

	add	r0, r0, #PAGE_SZ
	cmp	r0, r1
	blo	1b
	dsb
	mov	pc, lr
ENDPROC(v7wbi_flush_user_tlb_range)

/*
 *	v7wbi_flush_kern_tlb_range(start,end)
 *
 *	Invalidate a range of kernel TLB entries
 *
 *	- start - start address (may not be aligned)
 *	- end   - end address (exclusive, may not be aligned)
 */
ENTRY(v7wbi_flush_kern_tlb_range)
	dsb
	mov	r0, r0, lsr #PAGE_SHIFT		@ align address
	mov	r1, r1, lsr #PAGE_SHIFT
	mov	r0, r0, lsl #PAGE_SHIFT
	mov	r1, r1, lsl #PAGE_SHIFT
1:
#if defined(CONFIG_ARCH_MSM8X60) || defined(CONFIG_ARM_ERRATA_720789)
	ALT_SMP(mcr	p15, 0, r0, c8, c3, 3)	@ TLB invalidate U MVA all ASID (shareable)
#else
	ALT_SMP(mcr	p15, 0, r0, c8, c3, 1)	@ TLB invalidate U MVA (shareable)
#endif
	ALT_UP(mcr	p15, 0, r0, c8, c7, 1)	@ TLB invalidate U MVA
	add	r0, r0, #PAGE_SZ
	cmp	r0, r1
	blo	1b
	dsb
	isb
	mov	pc, lr
ENDPROC(v7wbi_flush_kern_tlb_range)

	__INIT

	/* define struct cpu_tlb_fns (see <asm/tlbflush.h> and proc-macros.S) */
	define_tlb_functions v7wbi, v7wbi_tlb_flags_up, flags_smp=v7wbi_tlb_flags_smp
