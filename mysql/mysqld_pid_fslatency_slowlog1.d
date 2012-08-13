#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_fslatency_slowlog1.d  Print slow filesystem I/O events.
 *
 * USAGE: ./mysql_pid_fslatency_slowlog1.d mysqld_PID
 *
 * This traces mysqld filesystem I/O during queries, and prints output when
 * the total I/O time during a query was longer than the MIN_FS_LATENCY_MS
 * tunable.  This requires tracing every query, whether it performs FS I/O
 * or not, which may add a noticable overhead.
 *
 * This is a monitoring tool (if Cloud Analytics is not available).
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

inline int MIN_FS_LATENCY_MS = 1000;

dtrace:::BEGIN
{
	min_ns = MIN_FS_LATENCY_MS * 1000000;
}

pid$1::*dispatch_command*:entry
{
	self->in_query = 1;
	self->io_count = 0;
	self->total_ns = 0;
}

pid$1::os_file_read:entry,
pid$1::os_file_write:entry,
pid$1::my_read:entry,
pid$1::my_write:entry
/self->in_query/
{
	self->start = timestamp;
}

pid$1::os_file_read:return,
pid$1::os_file_write:return,
pid$1::my_read:return,
pid$1::my_write:return
/self->start/
{
	self->total_ns += timestamp - self->start;
	self->io_count++;
	self->start = 0;
}

pid$1::*dispatch_command*:return
/self->in_query && (self->total_ns > min_ns)/
{
	printf("%Y filesystem total I/O during query > %d ms: %d ms, %d I/O\n",
	    walltimestamp, MIN_FS_LATENCY_MS, self->total_ns / 1000000,
	    self->io_count);
}

pid$1::*dispatch_command*:return
/self->in_query/
{
	self->in_query = 0;
	self->io_count = 0;
	self->total_ns = 0;
}
