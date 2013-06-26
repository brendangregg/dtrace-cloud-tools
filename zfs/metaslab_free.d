#!/usr/sbin/dtrace -s
/*
 * metaslab_free.d	Show ZFS metaslab percent free on allocations.
 *
 * ZFS switches to a slower allocation algorithm when the free size in a
 * metaslab (usually 16 Gbytes) is less than a percentage.  The slower
 * algorithm is best-fit instead of fast-fit.
 *
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at http://smartos.org/CDDL
 *
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file.
 *
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 *
 * Copyright (c) 2012 Joyent Inc., All rights reserved.
 * Copyright (c) 2012 Brendan Gregg, All rights reserved.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing ZFS metaslab alloc.  metaslab_df_free_pct = %d %%\n",
	    `metaslab_df_free_pct);
}

fbt::metaslab_df_alloc:entry
{
        this->pct = args[0]->sm_space * 100 / args[0]->sm_size;
        @[this->pct] = count();
}

profile:::tick-1s
{
        printf("\n%Y free %%pct by allocations:", walltimestamp);
        printa(@);
        trunc(@);
}
