#!/usr/sbin/dtrace -s
/*
 * erlang_localsend.d	Measure Erlang local process send time.
 *
 * I'm not sure this works, as the token_label (arg3) is always 0,
 * which I was hoping to use as a unique message ID.
 *
 * See otp/erts/emulator/beam/erlang_dtrace.d for probe details.
 */

#pragma D option dynvarsize=8m

erlang*:::message-send
{
	ts[copyinstr(arg1), arg3] = timestamp;
}

erlang*:::message-receive
/(this->p = copyinstr(arg0)) != NULL &&
    (this->ts = ts[this->p, arg3]) > 0/
{
	@["ns"] = quantize(timestamp - this->ts);
	ts[this->p, arg3] = 0;
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
