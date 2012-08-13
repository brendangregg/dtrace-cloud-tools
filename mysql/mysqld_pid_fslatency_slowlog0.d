#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_fslatency_slowlog0.d  Print slow filesystem I/O events.
 *
 * USAGE: ./mysql_pid_fslatency_slowlog0.d mysqld_PID
 *
 * This traces all mysqld filesystem I/O (including some that may be
 * asynchronous to queries and not causing query latency), and prints
 * those individual I/O taking longer than the MIN_FS_LATENCY_MS tunable.
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

pid$1::os_file_read:entry,
pid$1::os_file_write:entry,
pid$1::my_read:entry,
pid$1::my_write:entry
{
	self->start = timestamp;
}

pid$1::os_file_read:return,
pid$1::my_read:return
/self->start && (timestamp - self->start) > min_ns/
{
	this->ms = (timestamp - self->start) / 1000000;
	printf("%Y filesystem read > %d ms: %d ms\n", walltimestamp,
	    MIN_FS_LATENCY_MS, this->ms);
}

pid$1::os_file_write:return,
pid$1::my_write:return
/self->start && (timestamp - self->start) > min_ns/
{
	this->ms = (timestamp - self->start) / 1000000;
	printf("%Y filesystem write > %d ms: %d ms\n", walltimestamp,
	    MIN_FS_LATENCY_MS, this->ms);
}

pid$1::os_file_read:return,
pid$1::os_file_write:return,
pid$1::my_read:return,
pid$1::my_write:return
{
	self->start = 0;
}
