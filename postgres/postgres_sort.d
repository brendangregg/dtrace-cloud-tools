#!/usr/sbin/dtrace -s
/*
 * postgres_sort.d	Summarize PostgreSQL server sort latency.
 *
 * This requires the postgres DTrace provider.  It will trace all running
 * instances of postgres.
 *
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	trace("Tracing postgres sort latency. Ctrl-C to end.\n");
}

postgres*:::sort-start
{
	self->ts = timestamp;
	self->vts = vtimestamp;
}


postgres*:::sort-done
/self->ts/
{
	@["elapsed ns"] = quantize(timestamp - self->ts);
	@["CPU ns"] = quantize(vtimestamp - self->vts);
	self->ts = 0;
	self->vts = 0;
}
