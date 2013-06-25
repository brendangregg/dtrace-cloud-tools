#!/usr/sbin/dtrace -s
/*
 * tcpsackretrans.d	Trace TCP SACK fast retransmits with details.
 *
 * SEE ALSO: tcpretranssnoop*.d
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
 *	sdc6: ok
 */

#pragma D option quiet
#pragma D option switchrate=10hz
self string retrans;

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

	printf("%-20s %-17s %-16s %-16s %-6s\n", "TIME",
	    "TCP_STATE", "SRC", "DST", "PORT");
}

/* SACK fast retrinsmits */
fbt::tcp_sack_rexmit:entry  { self->tcp = args[0]; }
fbt::tcp_sack_rexmit:return { self->tcp = 0; }

mib:::tcpOutSackRetransSegs
/self->tcp/
{
	this->state = tcpstate[self->tcp->tcp_state] != NULL ?
	    tcpstate[self->tcp->tcp_state] : "<unknown>";
	printf("%-20Y %-17s %-16s %-16s %-6d\n", walltimestamp,
	    this->state,
	    /* just look at it. LOOK at it. */
	    inet_ntoa(&self->tcp->tcp_connp->connua_v6addr.connua_laddr._S6_un._S6_u32[3]),
	    inet_ntoa(&self->tcp->tcp_connp->connua_v6addr.connua_faddr._S6_un._S6_u32[3]),
	    ntohs(self->tcp->tcp_connp->u_port.connu_ports.connu_fport));
	self->tcp = 0;
}
