#!/usr/sbin/dtrace -s
/*
 * tcpslowstart.d	Show the in-effect slow start MSS value.
 *
 * This traces the congestion window size in terms of MSS for the first
 * sent data packet of an accepted connection.  Tuned using
 * tcp_slow_start_initial.
 *
 * Idea: Theo Schlossnagle
 *
 * While the probes this script uses are stable (tcp provider), it uses a
 * unstable variable (arg3), making the script unstable.  It's the args[N]
 * versions that are stable, not the argN versions.
 */

#pragma D option quiet
#pragma D option switchrate=5

dtrace:::BEGIN
{
	trace("Tracing tcp slow start.\n");
}

tcp:::accept-established
{
	/* key on the tcp_t, which is arg3 (undocumented and unstable) */
	a[arg3] = 1;
}

tcp:::send
/a[arg3] && (args[2]->ip_plength - args[4]->tcp_offset)/
{
	printf("%3d MSS: %15s -> %15s\n",
	    args[3]->tcps_cwnd / args[3]->tcps_mss,
	    args[2]->ip_saddr, args[2]->ip_daddr);
	a[arg3] = 0;
}
