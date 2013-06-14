#!/usr/sbin/dtrace -s
/*
 * riak_1blat.d		Riak 1st byte latency.d
 *
 * This is experimental, and makes assumptions about the operation
 * of beam that may be wrong.  It attempts to measure the 1st byte
 * latency of riak (well, beam.smp), by measuring the time from
 * a recv() to a writev() on the same file descriptor.
 */

syscall::recv:entry
/execname == "beam.smp"/
{
	self->fd = arg0 + 1;
}

syscall::recv:return
/self->fd/
{
	ts[pid, self->fd] = timestamp;
	self->fd = 0;
}

syscall::writev:entry
/ts[pid, arg0]/
{
	@["ns"] = quantize(timestamp - ts[pid, arg0]);
	ts[pid, arg0] = 0;
}

tick-10s
{
	printa(@); trunc(@);
}
