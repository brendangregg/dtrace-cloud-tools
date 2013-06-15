#!/usr/sbin/dtrace -s
/*
 * erlang_psched_thr.d	Erlang thread scheduled times.
 * 
 * This is based on thread-local variables for efficiency;
 * I checked it vs using an associative array keyed on the
 * Erlang PID, and there wasn't a difference.
 */

erlang*:::process-scheduled
{
	self->ts = timestamp;
}

erlang*:::process-unscheduled
/self->ts/
{
	@["ns"] = quantize(timestamp - self->ts);
	self->ts = 0;
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
