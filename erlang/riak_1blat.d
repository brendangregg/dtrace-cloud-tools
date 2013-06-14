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
	self->fd1 = arg0 + 1;
}

syscall::recv:return
/self->fd1/
{
	ts[pid, self->fd1] = timestamp;
	self->fd1 = 0;
}

syscall::writev:entry
/ts[pid, arg0 + 1]/
{
	@["ns"] = quantize(timestamp - ts[pid, arg0 + 1]);
	ts[pid, arg0 + 1] = 0;
}

tick-10s
{
	printa(@); trunc(@);
}
