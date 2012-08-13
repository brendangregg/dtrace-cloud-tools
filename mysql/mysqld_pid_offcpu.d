#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_offcpu.d	Trace off-CPU time during queries, showing stacks.
 *
 * USAGE: ./mysqld_pid_offcpu.d -p mysqld_PID
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
	min_ns = 10000000;
	printf("Tracing PID %d for queries longer than %d ms\n",
	    $target, min_ns / 1000000);
	printf("Hit Ctrl-C when ready for off-CPU report.\n\n");
}

pid$target::*dispatch_command*:entry
{
	self->start = timestamp;
}

sched:::off-cpu
/self->start/
{
	self->off = timestamp;
}

sched:::on-cpu
/self->off && (timestamp - self->off) > min_ns/
{
	@offcpu[stack(), ustack()] = quantize(timestamp - self->off);
	self->off = 0;
}

pid$target::*dispatch_command*:return
/self->start && (timestamp - self->start) > min_ns/
{
	@time = quantize(timestamp - self->start);
}

pid$target::*dispatch_command*:return
{
	self->start = 0;
	self->off = 0;
}

tick-1s,
dtrace:::END
{
	printf("MySQL query latency (ns):");
	printa(@time);
	clear(@time);
}

dtrace:::END
{
	printf("Top 10 off-CPU user & kernel stacks, by wait latency (ns):");
	trunc(@offcpu, 10);
}
