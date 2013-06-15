#!/usr/sbin/dtrace -s 
/*
 * erlang_heapshrink.d	Show a distribution of Erlang heap shrink sizes.
 *
 * See otp/erts/emulator/beam/erlang_dtrace.d for probe details.
 */

erlang*:::process-heap_shrink
{
	@["heap shrink bytes"] = quantize(arg1 - arg2);
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
