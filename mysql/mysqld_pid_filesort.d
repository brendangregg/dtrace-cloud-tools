#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_filesort.d  Print filesort latency distribution.
 *
 * USAGE: ./mysqld_pid_filesort.d -p mysqld_PID
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
	printf("Tracing MySQL PID %d... Hit Ctrl-C to end.\n", $target);
	start = timestamp;
}

pid$target::*dispatch_command*:entry
{
	@queries = count();
}

pid$target::*filesort[A-Z]*:entry
{
	self->start = timestamp;
	self->vstart = vtimestamp;
}

pid$target::*filesort[A-Z]*:return
/self->start/
{
	@dist["time"] = quantize(timestamp - self->start);
	@dist["on-CPU"] = quantize(vtimestamp - self->vstart);
	@total["on-CPU (ms)"] = sum(vtimestamp - self->vstart);
	@num = count();
	self->start = 0;
	self->vstart = 0;
}

dtrace:::END
{
	@total["tracing duration (ms)"] = sum(timestamp - start);
	normalize(@total, 1000000);
	printa("MySQL filesort: %@d, from queries: %@d; latency dist (ns):\n",
	    @num, @queries);
	printa(@dist);
	printf("Total times:\n");
	printa(@total);
}
