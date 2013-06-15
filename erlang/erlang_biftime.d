#!/usr/sbin/dtrace -s
/*
 * erlang_biftime.d	Time built-in function (BIF) calls.
 *
 * See otp/erts/emulator/beam/erlang_dtrace.d for probe details.
 */

#pragma D option dynvarsize=8m

erlang*:::bif-entry
{
	ts[copyinstr(arg0)] = timestamp;
}

erlang*:::bif-return
/(this->ts = ts[copyinstr(arg0)]) > 0/
{
	@[copyinstr(arg1), "ns"] = quantize(timestamp - this->ts);
	ts[copyinstr(arg0)] = 0;
}

profile:::tick-1s
{
	printa(@); trunc(@);
}
