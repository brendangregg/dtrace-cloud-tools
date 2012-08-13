#!/usr/sbin/dtrace -s
/*
 * tcpretranshosts.d	Show TCP hosts for retransmitted segments.
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

dtrace:::BEGIN
{
	trace("Tracing... Hit Ctrl-C for report.\n");
}

fbt::tcp_timer:entry  { self->in_tcp_timer = 1; self->retrans = 0; }
fbt::tcp_timer:return { self->in_tcp_timer = 0; self->retrans = 0; }

mib:::tcpRetransSegs  { self->retrans = 1; }

fbt::tcp_send_data:entry
/self->in_tcp_timer && self->retrans/
{
        this->iph = (ipha_t *)args[2]->b_rptr;
	@[inet_ntoa(&this->iph->ipha_src), inet_ntoa(&this->iph->ipha_dst)] = count();
}

dtrace:::END
{
	printf("  %-32s %-32s %8s\n", "SRC", "DST", "COUNT");
	printa("  %-32s %-32s %@8d\n", @);
}
