#!/usr/sbin/dtrace -s
/*
 * nodeslower.d		Show node.js HTTP server requests slower than threshold.
 *
 * USAGE: nodeslower.d [min_ms]
 *    eg,
 *        nodeslower.d 10	# show requests slower than 10 ms
 *        nodeslower.d 		# show all requests
 *
 * Requires the node DTrace provider, and a working version of the node
 * translator (/usr/lib/dtrace/node.d).
 *
 * Copyright (c) 2013 Joyent Inc., All rights reserved.
 * Copyright (c) 2013 Brendan Gregg, All rights reserved.
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
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option dynvarsize=8m
#pragma D option switchrate=10

dtrace:::BEGIN
{
	min_ns = $1 * 1000000;
	printf("Tracing node.js HTTP server ops slower than %d ms\n", $1);
        printf("%-20s %-6s %6s %s\n", "TIME", "PID", "ms", "URL");
}

node*:::http-server-request
{
	this->fd = args[1]->fd;
	url[pid, this->fd] = args[0]->url;
	ts[pid, this->fd] = timestamp;
}

node*:::http-server-response
{
	this->fd = args[0]->fd;
	/* FALLTHRU */
}

node*:::http-server-response
/(this->start = ts[pid, this->fd]) &&
    (this->delta = timestamp - this->start) > min_ns/
{
        printf("%-20Y %-6d %6d %s\n", walltimestamp, pid,
	    this->delta / 1000000, url[pid, this->fd]);
}

node*:::http-server-response
/this->start/
{
	ts[pid, this->fd] = 0;
	url[pid, this->fd] = 0;
}
