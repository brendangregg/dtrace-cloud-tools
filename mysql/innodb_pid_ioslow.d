#!/usr/sbin/dtrace -s
/*
 * innodb_pid_ioslow.d	Trace slow innodb storage I/O.
 *
 * USAGE: ./innodb_pid_ioslow.d -p mysqld_PID [interval]
 *
 * This traces innodb at the OS interface: os_file_read() and os_file_write().
 * This includes back-end query I/O, but not other types including log I/O.
 *
 * This may be easier (albiet more inclusive) to measure at the VFS/ZFS
 * interface.  That would require the fbt provider, which isn't available
 * in zones.
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
 *
 * SEE ALSO: innodb_pid_latency.d
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option bufsize=128k

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
	printf("Tracing... Min query time: %d ms. ", $1);
	printf("TIME & CPU are in ms.\n\n");
	printf(" %-4s %-4s %-7s %s\n", "TIME", "CPU", "SIZE(b)", "PATH");
}

pid$target::*os_file_read*:entry,
pid$target::*os_file_write*:entry
{
	self->start = timestamp;
	self->vstart = vtimestamp;
}

syscall::*read*:entry,syscall::*write*:entry
/self->start/
{
	/* easier to fetch them now than from the C++ args */
	self->fd = arg0 + 1;
	self->bytes = arg2;
}

pid$target::*os_file_read*:return  { this->dir = "R"; }
pid$target::*os_file_write*:return { this->dir = "W"; }

pid$target::*os_file_read*:return,
pid$target::*os_file_write*:return
/self->start && (timestamp - self->start) > min_ns/
{
	this->time = (timestamp - self->start) / 1000000;
	this->vtime = (vtimestamp - self->vstart) / 1000000;
	printf(" %-4d %-4d %-7d %s\n", this->time, this->vtime,
	    self->bytes, self->fd ? fds[self->fd - 1].fi_pathname : "");
}

pid$target::*os_file_read*:return,
pid$target::*os_file_write*:return
/self->start/
{
	self->start = 0;
	self->vstart = 0;
	self->fd = 0;
	self->bytes = 0;
}
