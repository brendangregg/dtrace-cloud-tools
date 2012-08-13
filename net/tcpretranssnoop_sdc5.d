#!/usr/sbin/dtrace -s
/*
 * tcpretranssnoop.d	Trace TCP retransmitted segments with details.
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
#pragma D option switchrate=10hz

dtrace:::BEGIN
{
	/* from /usr/include/inet/tcp.h */
	tcpstate[-6] = "TCPS_CLOSED";
	tcpstate[-5] = "TCPS_IDLE";
	tcpstate[-4] = "TCPS_BOUND";
	tcpstate[-3] = "TCPS_LISTEN";
	tcpstate[-2] = "TCPS_SYN_SENT";
	tcpstate[-1] = "TCPS_SYN_RCVD";
	tcpstate[0] = "TCPS_ESTABLISHED";
	tcpstate[1] = "TCPS_CLOSE_WAIT";
	tcpstate[2] = "TCPS_FIN_WAIT_1";
	tcpstate[3] = "TCPS_CLOSING";
	tcpstate[4] = "TCPS_LAST_ACK";
	tcpstate[5] = "TCPS_FIN_WAIT_2";
	tcpstate[6] = "TCPS_TIME_WAIT";

	printf("%-20s %-17s %-16s %-16s %-6s\n", "TIME", "TCP_STATE",
	    "SRC", "DST", "PORT");
}

fbt::tcp_timer:entry  { self->in_tcp_timer = 1; self->retrans = 0; }
fbt::tcp_timer:return { self->in_tcp_timer = 0; self->retrans = 0; }

mib:::tcpRetransSegs  { self->retrans = 1; }

fbt::tcp_send_data:entry
/self->in_tcp_timer && self->retrans/
{
        this->iph = (ipha_t *)args[2]->b_rptr;
	this->state = tcpstate[args[0]->tcp_state] != NULL ?
	    tcpstate[args[0]->tcp_state] : "<unknown>";
	printf("%-20Y %-17s %-16s %-16s %-6d\n", walltimestamp, this->state,
	    inet_ntoa(&this->iph->ipha_src), inet_ntoa(&this->iph->ipha_dst),
	    ntohs(args[0]->tcp_connp->u_port.tcpu_ports.tcpu_fport));
	self->retrans = 0;
}
