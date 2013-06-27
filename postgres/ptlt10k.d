#!/usr/sbin/dtrace -s
/*
 * ptlt10k.d		Postgres Transaction Latency Trace.
 *
 * This traces Postgres transactions using the DTrace postgres provider.  All
 * running instances of postgres will be traced.
 *
 * This emits basic details for consumption by other tools.  It ideally
 * captures at least 10,000 transactions.  It has a 15 minute timeout if that
 * is not possible.
 *
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet
#pragma D option switchrate=5

dtrace:::BEGIN
{
	printf("ENDTIME(us) LATENCY(ns) PID\n");
	start = timestamp;
	n = 0;
}

postgres*:::transaction-start
{
	self->ts = timestamp;
}

postgres*:::transaction-commit,
postgres*:::transaction-abort
/self->ts/
{
	printf("%d %d %d\n",
	    (timestamp - start) / 1000, timestamp - self->ts, pid);
	self->ts = 0;
}

postgres*:::transaction-start
/n++ > 10100/
{
	exit(0);
}

profile:::tick-15m { exit(0); }
