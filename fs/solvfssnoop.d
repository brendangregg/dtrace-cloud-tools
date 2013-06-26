#!/usr/sbin/dtrace -s
/*
 * solvfssnoop.d	Solaris VFS operation snoop.
 *
 * As this traces VFS, this includes all file system types, including
 * socket.  See the operations it traces below.
 *
 * This is from the DTrace book, chapter 5. See http://www.dtracebook.com.
 *
 * 18-Jun-2010	Brendan Gregg	Created this.
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option switchrate=10hz

dtrace:::BEGIN
{
	printf("%-12s %6s %6s %-12.12s %-12s %-4s %s\n", "TIME(ms)", "UID",
	    "PID", "PROCESS", "CALL", "KB", "PATH");
}

/* see /usr/include/sys/vnode.h */

fbt::fop_read:entry, fbt::fop_write:entry
{
	self->path = args[0]->v_path;
	self->kb = args[1]->uio_resid / 1024;
}

fbt::fop_open:entry
{
	self->path = (*args[0])->v_path;
	self->kb = 0;
}

fbt::fop_close:entry, fbt::fop_ioctl:entry, fbt::fop_getattr:entry,
fbt::fop_readdir:entry
{
	self->path = args[0]->v_path;
	self->kb = 0;
}

fbt::fop_read:entry, fbt::fop_write:entry, fbt::fop_open:entry,
fbt::fop_close:entry, fbt::fop_ioctl:entry, fbt::fop_getattr:entry,
fbt::fop_readdir:entry
/execname != "dtrace" && ($$1 == NULL || $$1 == execname)/
{
	printf("%-12d %6d %6d %-12.12s %-12s %-4d %s\n", timestamp / 1000000,
	    uid, pid, execname, probefunc, self->kb,
	    self->path != NULL ? stringof(self->path) : "<null>");
}

fbt::fop_read:entry, fbt::fop_write:entry, fbt::fop_open:entry,
fbt::fop_close:entry, fbt::fop_ioctl:entry, fbt::fop_getattr:entry,
fbt::fop_readdir:entry
{
	self->path = 0; self->kb = 0;
}
