#!/usr/sbin/dtrace -s
/*
 * erlang_msgqueue.d	Erlang message queue length.
 */

erlang*:::message-queued
{
	@["qlen"] = quantize(arg2);
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
