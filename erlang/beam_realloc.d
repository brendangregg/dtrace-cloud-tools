#!/usr/sbin/dtrace -s
/*
 * beam_realloc.d	erts_alcu_realloc_thr_spec() call statistics.
 *
 * USAGE: ./beam_realloc.d -p PID
 *
 * This uses the DTrace pid provider to dynamically trace Erlang/beam.smp
 * internals.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	/* prime for printing */
	@num = sum(0);
	@bytes = sum(0);
}

pid$target::erts_alcu_realloc_thr_spec:entry
{
	@num = sum(1);
	@bytes = sum(arg3);
}

profile:::tick-1s
{
	printf("%Y ", walltimestamp);
	printa("realloc: %4@d calls %@8d bytes\n", @num, @bytes);
	clear(@num);
	clear(@bytes);
}
