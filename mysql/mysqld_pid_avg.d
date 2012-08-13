#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_avg.d	Print average query latency every second, plus more.
 *
 * USAGE: ./mysqld_pid_avg.d -p mysqld_PID
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

dtrace:::BEGIN
{
	printf("Tracing PID %d...\n\n", $target);
	printf("%-20s %10s %8s %8s %8s\n", "TIME", "QUERIES", "1+sec_Qs",
	    "AVG(ms)", "MAX(ms)");
}

pid$target::*dispatch_command*:entry
{
	self->start = timestamp;
}

pid$target::*dispatch_command*:return
/self->start && (this->time = (timestamp - self->start))/
{
	@avg = avg(this->time);
	@max = max(this->time);
	@num = count();
}

pid$target::*dispatch_command*:return
/self->start && (this->time > 1000000000)/
{
	@slow = count();
}

pid$target::*dispatch_command*:return
{
	self->start = 0;
}

profile:::tick-1s
{
	normalize(@avg, 1000000);
	normalize(@max, 1000000);
	printf("%Y ", walltimestamp);
	printa("%@10d %@8d %@8d %@8d", @num, @slow, @avg, @max);
	printf("\n");
	clear(@num); clear(@slow); clear(@avg); clear(@max);
}

dtrace:::END
{
	trunc(@num); trunc(@slow); trunc(@avg); trunc(@max);
}
