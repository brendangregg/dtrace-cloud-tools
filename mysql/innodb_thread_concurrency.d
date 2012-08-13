#!/usr/sbin/dtrace -s
/*
 * innodb_thread_concurrency.d  measure thread concurrency sleeps
 *
 * USAGE: ./innodb_thread_concurrency.d -p mysqld_PID
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
 *      5.0.51a: ok
 */

pid$target::srv_conc_enter_innodb:entry
{
	self->srv = 1;
}

pid$target::os_thread_sleep:entry
/self->srv/
{
	@["innodb srv sleep (ns)"] = quantize(arg0 * 1000);
}

pid$target::srv_conc_enter_innodb:return
{
	self->srv = 0;
}

pid$target::*dispatch_command*:entry
{
	self->start = timestamp;
}

pid$target::*dispatch_command*:return
/self->start/
{
	@["query time (ns)"] = quantize(timestamp - self->start);
	self->start = 0;
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
