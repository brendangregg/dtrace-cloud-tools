#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_syscall_offcpu.d	Off-CPU time during query syscalls + stacks.
 *
 * USAGE: ./mysqld_pid_syscall_offcpu.d -p mysqld_PID
 *
 * This was written as a version of mysqld_pid_offcpu.d which doesn't use
 * the sched provider (which isn't available in the smartmachine).
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
#pragma D option switchrate=5hz

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

syscall:::entry
/self->start/
{
	self->off_ts = timestamp;
	self->off_vts = vtimestamp;
}

syscall:::return
/self->off_ts/
{
	this->cpu_time = vtimestamp - self->off_vts;
	this->off_time = timestamp - self->off_ts - this->cpu_time;
}

syscall:::return
/self->off_ts && this->off_time > min_ns/
{
	@offcpu[ustack()] = quantize(this->off_time);
	printf("%Y captured stack @ %d ms off-CPU\n", walltimestamp,
	    this->off_time / 1000000);
}

syscall:::return
{
	self->off_ts = 0;
	self->off_vts = 0;
}

pid$target::*dispatch_command*:return
{
	self->start = 0;
}

dtrace:::END
{
	printf("Top 10 off-CPU user stacks, by wait latency (ns):");
	trunc(@offcpu, 10);
}
