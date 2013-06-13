#!/usr/sbin/dtrace -s
/*
 * erlang_plifefunc.d	Erlang process life span, with function.
 */

#pragma D option dynvarsize=8m

BEGIN
{
	trace("Tracing Erlang process times. Ctrl-C to end.\n");
}

erlang*:::process-spawn
{
	this->p = copyinstr(arg0);
  name[this->p] = copyinstr(arg1);
	ts[this->p] = timestamp;
}

erlang*:::process-exit
/(this->p = copyinstr(arg0)) != NULL && (this->ts = ts[this->p]) > 0/
{
	@[name[this->p], "ns"] = quantize(timestamp - this->ts);
	ts[this->p] = 0;
	name[this->p] = 0;
}
