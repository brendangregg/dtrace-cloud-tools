#!/usr/sbin/dtrace -s
/*
 * innodb_pid_iolatency.d	Show storage latency distribution.
 *
 * USAGE: ./innodb_pid_iolatency.d -p mysqld_PID [interval]
 *
 * This traces innodb at the OS interface: os_file_read() and os_file_write().
 * This includes back-end query I/O, but not other types including log I/O.
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
 * SEE ALSO: innodb_pid_ioslow.d
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option bufsize=32k

dtrace:::BEGIN
{
	printf("Tracing PID %d... Hit Ctrl-C to end.\n", $target);
	interval = $1 ? $1 : 1;
	secs = interval;
}

pid$target::*os_file_read*:entry,
pid$target::*os_file_write*:entry
{
	self->start = timestamp;
}

pid$target::*os_file_read*:return  { this->dir = "read"; }
pid$target::*os_file_write*:return { this->dir = "write"; }

pid$target::*os_file_read*:return,
pid$target::*os_file_write*:return
/self->start/
{
	@time[this->dir] = quantize(timestamp - self->start);
	@num = count();
	self->start = 0;
}

profile:::tick-1s
{
	secs--;
}

profile:::tick-1s
/secs == 0/
{
	normalize(@num, interval);
	printa("\ninnodb IOPS: %@d; storage latency by direction (ns):",
	    @num);
	printa(@time);
	clear(@time); clear(@num);
	secs = interval;
}

dtrace:::END
{
	trunc(@time); trunc(@num);
}
