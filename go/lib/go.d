/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */
/*
 * Copyright (c) 2013, Joyent, Inc. All rights reserved.
 */

inline uintptr_t goarg0 = *(uintptr_t *)copyin(uregs[R_SP] + 1 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg1 = *(uintptr_t *)copyin(uregs[R_SP] + 2 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg2 = *(uintptr_t *)copyin(uregs[R_SP] + 3 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg3 = *(uintptr_t *)copyin(uregs[R_SP] + 4 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg4 = *(uintptr_t *)copyin(uregs[R_SP] + 5 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg5 = *(uintptr_t *)copyin(uregs[R_SP] + 6 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg6 = *(uintptr_t *)copyin(uregs[R_SP] + 7 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg7 = *(uintptr_t *)copyin(uregs[R_SP] + 8 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg8 = *(uintptr_t *)copyin(uregs[R_SP] + 9 * sizeof (uintptr_t), sizeof (uintptr_t));
inline uintptr_t goarg9 = *(uintptr_t *)copyin(uregs[R_SP] + 10 * sizeof (uintptr_t), sizeof (uintptr_t));
