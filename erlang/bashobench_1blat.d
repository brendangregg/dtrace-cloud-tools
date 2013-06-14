#!/usr/sbin/dtrace -s
/*
 * bashobench_1blat.d	Basho bench 1st byte latency.d
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
