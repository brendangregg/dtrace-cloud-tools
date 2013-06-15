#!/usr/sbin/dtrace -s
/*
 * erlang_msgsize.d	Erlang message send/receive size (words).
 */

erlang*:::message-send
{
	@[probename, "words"] = quantize(arg2);
}

erlang*:::message-send-remote
{
	@[probename, "words"] = quantize(arg3);
}

erlang*:::message-receive,
erlang*:::message-queued
{
	@[probename, "words"] = quantize((int)arg1);
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
