#!/usr/sbin/dtrace -s
/*
 * zonecalls.d	show top 25 syscalls by zone and process.
 *
 * USAGE: ./zonecalls.d [interval]	# default 1 sec
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
#pragma D option defaultargs
#pragma D option bufsize=512k

inline int TOP = 25;

dtrace:::BEGIN
{
	interval = $1 ? $1 : 1;
}

dtrace:::BEGIN
{
	printf("Top %d syscalls by zone and process. Output every %d secs.\n",
	    TOP, interval);
	secs = interval;
}

syscall:::entry
{
	@[zonename, execname, probefunc] = count();
	@["", "", "TOTAL"] = count();
}

profile:::tick-1sec
{
	secs--;
}

profile:::tick-1sec
/secs == 0/
{
	trunc(@, TOP + 1);
	printf("\n %-20s %-20s %-20s %s\n", "ZONE", "PROCESS", "SYSCALL",
	    "COUNT");
	printa(" %-20s %-20s %-20s %@d\n", @);
	secs = interval;
	trunc(@);
}

dtrace:::END
{
	trunc(@);
}
