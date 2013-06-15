#!/usr/sbin/dtrace -s
/*
 * erlang_gc.d		Time Erlang garbage collect.
 *
 * See otp/erts/emulator/beam/erlang_dtrace.d for probe details.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	trace("Tracing Erlang GC time.\n")
}

erlang*:::gc_major-start,
erlang*:::gc_minor-start
{
	/*
	 * I'm using a thread local variable since erts_garbage_collect()
	 * like like it begins and ends on the same thread.
	 */
	self->ts = timestamp;
}

erlang*:::gc_major-end,
erlang*:::gc_minor-end
/self->ts/
{
	@[probename, "ns"] = quantize(timestamp - self->ts);
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
