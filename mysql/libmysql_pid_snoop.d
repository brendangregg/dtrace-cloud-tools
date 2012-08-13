#!/usr/sbin/dtrace -Zs
/*
 * libmysql_pid_snoop.d		Snoop MySQL queries.
 *
 * From the "DTrace" book, chapter 10.
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
 */

#pragma D option quiet
#pragma D option switchrate=10hz

dtrace:::BEGIN
{
	printf("%-8s %6s %3s %s\n", "TIME(ms)", "Q(ms)", "RET", "QUERY");
	timezero = timestamp;
}

pid$target::mysql_query:entry,
pid$target::mysql_real_query:entry
{
	self->query = copyinstr(arg1);
	self->start = timestamp;
}

pid$target::mysql_query:return,
pid$target::mysql_real_query:return
/self->start/
{
	this->time = (timestamp - self->start) / 1000000;
	this->now = (timestamp - timezero) / 1000000;
	printf("%-8d %6d %3d %s\n", this->now, this->time, arg1, self->query);
	self->start = 0; self->query = 0;
}
