#!/usr/sbin/dtrace -s

#pragma D option quiet

BEGIN
{
	trace("Tracing Erlang GC time.\n")
}

erlang*:::gc_major-start,
erlang*:::gc_minor-start
{
	/*
	 * Thread local variable, since erts_garbage_collect() looks
	 * like it begins and ends on the same thread.
	 */
	self->ts = timestamp;
}

erlang*:::gc_major-end,
erlang*:::gc_minor-end
/self->ts/
{
	@[probename, "ns"] = quantize(timestamp - self->ts);
}

tick-1s
{
	printa(@);
	trunc(@);
}
