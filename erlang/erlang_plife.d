#!/usr/sbin/dtrace -s
/*
 * erlang_plife.d	Erlang process life span.
 */

#pragma D option dynvarsize=8m

erlang*:::process-spawn
{
	ts[copyinstr(arg0)] = timestamp;
}

erlang*:::process-exit
/(this->ts = ts[copyinstr(arg0)]) > 0/
{
	@["ns"] = quantize(timestamp - this->ts);
	ts[copyinstr(arg0)] = 0;
}

profile:::tick-1s
{
	printa(@); trunc(@);
}
