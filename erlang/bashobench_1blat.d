#!/usr/sbin/dtrace -s
/*
 * bashobench_1blat.d	Basho bench 1st byte latency.d
 *
 * This works by tracing the time from a writev() to a FD, to when the
 * first recv() on the same FD completes.  These syscalls are an
 * implementation detail of Erlang/beam.smp, and may change at any time.
 */

syscall::writev:entry
/execname == "beam.smp"/
{
	ts[pid, arg0 + 1] = timestamp;
}

syscall::recv:entry
/ts[pid, arg0 + 1]/
{
	self->fd = arg0 + 1;
}

syscall::recv:return
/self->fd && ts[pid, self->fd + 1]/
{
	@["ns"] = quantize(timestamp - ts[pid, self->fd]);
	ts[pid, self->fd] = 0;
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
