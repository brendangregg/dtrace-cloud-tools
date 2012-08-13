#!/usr/sbin/dtrace -s
/*
 * libmysql_pid_connect.d	Trace MySQL connect latency.
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
	printf("%-20s %16s %12s %6s %8s\n", "TIME", "HOST", "DB", "PORT", "LAT");
}

pid$target::mysql_real_connect:entry
{
	self->host = arg1 ? copyinstr(arg1) : "<null>";
	self->db = arg4 ? copyinstr(arg4) : "<null>";
	self->port = arg5;
	self->start = timestamp;
}

pid$target::mysql_real_connect:return
/self->start/
{
	this->delta = timestamp - self->start;
	printf("%-20Y %16s %12s %6d %8d ms\n", walltimestamp,
	    self->host, self->db, self->port, this->delta / 1000000);
	self->host = 0;
	self->db = 0;
	self->port = 0;
	self->start = 0;
}
