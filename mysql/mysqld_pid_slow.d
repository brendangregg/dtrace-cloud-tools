#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_slow.d	Trace queries slower than specified ms.
 *
 * USAGE: ./mysqld_pid_slow.d -p mysqld_PID min_ms
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
#pragma D option switchrate=10hz

dtrace:::BEGIN
/$1 == 0/
{
	printf("USAGE: %s -p PID min_ms\n\n", $$0);
	printf("\teg: %s -p 12345 100\n", $$0);
	exit(1);
}

dtrace:::BEGIN
{
	min_ns = $1 * 1000000;
	printf("Tracing... Min query time: %d ns.\n\n", min_ns);
	printf(" %-8s %-8s %s\n", "TIME(ms)", "CPU(ms)", "QUERY");
}

pid$target::*dispatch_command*:entry
{
	self->query = copyinstr(arg2);
	self->start = timestamp;
	self->vstart = vtimestamp;
}

pid$target::*dispatch_command*:return
/self->start && (timestamp - self->start) > min_ns/
{
	this->time = (timestamp - self->start) / 1000000;
	this->vtime = (vtimestamp - self->vstart) / 1000000;
	printf(" %-8d %-8d %S\n", this->time, this->vtime, self->query);
}

pid$target::*dispatch_command*:return
{
	self->query = 0;
	self->start = 0;
	self->vstart = 0;
}
