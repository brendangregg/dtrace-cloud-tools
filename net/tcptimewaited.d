#!/usr/sbin/dtrace -s
/*
 * tcptimewaited.d	Summarize TCP time waited ms.
 *
 * This traces the tcp_t->tcp_ms_we_have_waited value during tcp_timer(),
 * which TCP must track for the max rexmit interval.
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

	printf("Tracing... Hit Ctrl-C to end.\n");
}

fbt::tcp_timer:entry
{
	this->connp = (conn_t *)arg0;
	this->tcp = (tcp_t *)this->connp->conn_proto_priv.cp_tcp;
	this->waited = this->tcp->tcp_ms_we_have_waited;
}

fbt::tcp_timer:entry
/this->waited/
{
	this->fport = ntohs(this->tcp->tcp_connp->u_port.tcpu_ports.tcpu_fport);
	this->state = tcpstate[this->tcp->tcp_state] != NULL ?
	    tcpstate[this->tcp->tcp_state] : "<unknown>";
	@[this->state, this->fport] = lquantize(this->waited, 0, 20000, 100);
}
