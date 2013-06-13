#!/usr/sbin/dtrace -s
/*
 * bashobench_1blat.d	Basho bench 1st byte latency.d
 *
 * Measures the time from a write on a FD, to the 1st successful read
 * from the same FD.  This relies on the syscalls used by the Erlang beam.smp
 * implementation, and may not work on different beam versions.
 */

syscall::writev:entry
/execname == "beam.smp"/
{
	ts[arg0 + 1] = timestamp;
}

syscall::recv:entry
{
	self->fd = arg0;
}

syscall::recv:return
/self->fd && ts[self->fd + 1]/
{
	@["ns"] = quantize(timestamp - ts[self->fd + 1]);
	ts[self->fd + 1] = 0;
}

syscall::recv:return
/self->fd/
{
	self->fd = 0;
}

tick-1s
{
	printa(@); trunc(@);
}
