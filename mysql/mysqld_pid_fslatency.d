#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_fslatency.d  Print file system latency distribution.
 *
 * USAGE: ./mysqld_pid_fslatency.d -p mysqld_PID
 *
 * NOTE: This is designed to be runable from a zone.  From the global zone,
 * you can use mysqld_zfs_latency.d
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
	printf("Tracing PID %d... Hit Ctrl-C to end.\n", $target);
}

pid$target::os_file_read:entry,
pid$target::os_file_write:entry,
pid$target::my_read:entry,
pid$target::my_write:entry
{
	self->start = timestamp;
}

pid$target::os_file_read:return  { this->dir = "read"; }
pid$target::os_file_write:return { this->dir = "write"; }
pid$target::my_read:return       { this->dir = "read"; }
pid$target::my_write:return      { this->dir = "write"; }

pid$target::os_file_read:return,
pid$target::os_file_write:return,
pid$target::my_read:return,
pid$target::my_write:return
/self->start/
{
	@time[this->dir] = quantize(timestamp - self->start);
	@num = count();
	self->start = 0;
}

dtrace:::END
{
	printa("MySQL filesystem I/O: %@d; latency (ns):\n", @num);
	printa(@time);
	clear(@time); clear(@num);
}
