#!/usr/sbin/dtrace -s 
/*
 * cpuutil.d	sample and summarize zone and execname CPU usage.
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

profile:::profile-997
/curthread->t_pri != -1/
{
        @[zonename, execname] = count();
}

profile:::tick-1s,
dtrace:::END
{
        printf("\non-CPU samples by zone and process, @997 Hertz:\n");
        printa("   %-16s %-16s %@4d\n", @);
        trunc(@);
}
