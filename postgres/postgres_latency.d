#!/usr/sbin/dtrace -s
/*
 * postgres_latency.d	Summarize PostgreSQL server transaction latency.
 *
 * This requires the postgres DTrace provider.  It will trace all running
 * instances of postgres.
 *
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	trace("Tracing postgres server transaction latency. Ctrl-C to end.\n");
}

postgres*:::transaction-start
{
	self->ts = timestamp;
}


postgres*:::transaction-commit,
postgres*:::transaction-abort
/self->ts/
{
	@["ns"] = quantize(timestamp - self->ts);
	self->ts = 0;
}
