#!/usr/sbin/dtrace -s
/*
 * mysqld_zfs_iolatency.d	Print zfs latency distribution per second.
 *
 * USAGE: ./mysqld_zfs_iolatency.d -p mysqld_PID [interval]
 *
 * This traces all back-end I/O, including query and log.  This traces ZFS,
 * and so only works if storage is ZFS.  You also need privilege to trace
 * the fbt provider (dtrace_kernel).
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
 * SEE ALSO: mysqld_pid_iolatency.d
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option bufsize=32k

dtrace:::BEGIN
{
	interval = $1 ? $1 : 600;
	printf("Tracing PID %d... Report every %d secs, or hit Ctrl-C.\n\n",
	    $target, interval);
	secs = 0;
}

fbt::zfs_read:entry,
fbt::zfs_write:entry
/pid == $target/
{
	self->start = timestamp;
}

fbt::zfs_read:return  { this->dir = "read"; }
fbt::zfs_write:return { this->dir = "write"; }

fbt::zfs_read:return,
fbt::zfs_write:return
/self->start/
{
	@time[this->dir] = quantize(timestamp - self->start);
	@num = count();
	self->start = 0;
}

profile:::tick-1s { secs++; }

profile:::tick-1s,
dtrace:::END
/secs == interval || probename == "END"/
{
	normalize(@num, secs);
	printf("%Y  ", walltimestamp);
	printa("MySQL IOPS: %@d; ZFS latency by dir (ns):\n", @num);
	printa(@time);
	clear(@time); clear(@num);
	secs = 0;
}
