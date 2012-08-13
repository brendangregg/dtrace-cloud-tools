#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_querys.d	Print query count per interval.
 *
 * USAGE: ./mysqld_pid_querys.d mysqld_PID [interval]
 *
 * This delibrately avoids using -p and $target so that it can be run
 * while other DTrace is used.
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
 *
 * TESTED: these pid-provider probes may only work on some mysqld versions.
 *	5.0.51a: ok
 */

#pragma D option quiet
#pragma D option defaultargs

dtrace:::BEGIN
{
	interval = $2 ? $2 : 600;
	printf("Tracing PID %d... Report every %d secs, or hit Ctrl-C.\n\n",
	    $1, interval);
	secs = 0;
}

dtrace:::BEGIN
/$1 == 0/
{
	printf("USAGE: ./mysqld_pid_querys.d PID [interval]\n");
	exit(0);
}

pid$1::*dispatch_command*:entry
{
	@num = count();
}

profile:::tick-1s { secs++; }

profile:::tick-1s,
dtrace:::END
/secs == interval || probename == "END"/
{
	normalize(@num, secs);
	printf("%Y  ", walltimestamp);
	printa("MySQL queries/second: %@d\n", @num);
	clear(@num);
	secs = 0;
}
