#!/usr/sbin/dtrace -s
/*
 * mysqld_command.d  Commands with latency distributions.
 *
 * USAGE: ./mysqld_command.d
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
 * TESTED: not yet! need a mysqld that has the command-start/done probes.
 *
 * 25-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing mysqld commands... Hit Ctrl-C to end.\n");
}

mysql*:::command-start
{
	self->start = timestamp;
	self->cmd = arg1;
}

mysql*:::command-done
/self->start/
{
	@time[pid, self->cmd] = quantize(timestamp - self->start);
	@num = count();
	self->start = 0;
	self->cmd = 0;
}

profile:::tick-1s
{
	printf("\nMySQL commands/second total: ");
	printa("%@d; commands latency (ns) by pid & cmd:", @num);
	printa(@time);
	clear(@time);
	clear(@num);
}

dtrace:::END
{
	trunc(@time);
	trunc(@num);
}
