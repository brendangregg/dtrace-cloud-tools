#!/usr/sbin/dtrace -s
/*
 * tcprefused.d		Trace refused TCP connect() and accept()s.
 *
 * This is intended to debug sessions with connection refused errors (getting
 * RSTs).  It uses the tcp probes that only trace the codepaths related to
 * refusing connections (ie, low rate).
 */

#pragma D option switchrate=5

tcp:::connect-refused
{
	printf("%s -> %s:%d", args[3]->tcps_laddr,
	    args[3]->tcps_raddr, args[3]->tcps_rport);
}

tcp:::accept-refused
{
	printf("%s -> %s:%d", args[3]->tcps_raddr,
	    args[3]->tcp_laddr, args[3]->tcps_lport);
}
