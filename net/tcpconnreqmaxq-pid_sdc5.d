#!/usr/sbin/dtrace -s
/*
 * tcpconnreqmaxq-pid.d	  Show details for the TCP connection queue, with pid.
 *
 * This traces tcpListenDrop and the active value for tcp_conn_req_cnt_q,
 * to evaluate tuning of tcp_conn_req_max_q.  The pid shown is the cached pid
 * in TCP; the actual process that created the socket may have dissapeared.
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
 * TESTED: this fbt provider based script may only work on some OS versions.
 *	121: ok
 */

#pragma D option quiet
#pragma D option switchrate=4hz

dtrace:::BEGIN
{
	printf("Tracing... Hit Ctrl-C to end.\n");
}

fbt::tcp_conn_request:entry
{
	this->connp = (conn_t *)arg0;
	this->tcp = (tcp_t *)this->connp->conn_proto_priv.cp_tcp;
	self->max = strjoin("max_q:", lltostr(this->tcp->tcp_conn_req_max));
	self->pid = strjoin("cpid:", lltostr(this->tcp->tcp_cpid));
	@[self->pid, self->max] = quantize(this->tcp->tcp_conn_req_cnt_q);
}

mib:::tcpListenDrop
{
	this->max = self->max;
	this->pid = self->pid;
	this->max != NULL ? this->max : "<null>";
	this->pid != NULL ? this->pid : "<null>";
	@drops[this->pid, this->max] = count();
	printf("%Y %s:%s %s\n", walltimestamp, probefunc, probename, this->pid);
}

fbt::tcp_conn_request:return
{
	self->max = 0;
	self->pid = 0;
}

dtrace:::END
{
	printf("tcp_conn_req_cnt_q distributions:\n");
	printa(@);
	printf("tcpListenDrops:\n");
	printa("   %-32s %-32s %@8d\n", @drops);
}
