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
	/* key on pid and FD + 1 */
	ts[pid, arg0 + 1] = timestamp;
}

syscall::recv:entry
/ts[pid, arg0 + 1]/
{
	self->fd1 = arg0 + 1;
}

syscall::recv:return
/self->fd1 && ts[pid, self->fd1]/
{
	@["ns"] = quantize(timestamp - ts[pid, self->fd1]);
	ts[pid, self->fd1] = 0;
}

syscall::recv:return
/self->fd1/
{
	self->fd1 = 0;
}

tick-1s
{
	printa(@); trunc(@);
}
