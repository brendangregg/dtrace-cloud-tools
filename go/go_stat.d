#!/usr/sbin/dtrace -s
/*
 * go_stat.d	go status tool
 *
 * USAGE: go_stat.d -p PID [interval]
 *
 * COLUMNS:
 * 
 * 	main		main package functions
 * 	os		os package functions
 * 	syscalls	system calls
 *
 * NOTE: the
 * If an interval is not provided, this defaults to 1 second.
 */

#pragma D option defaultargs
#pragma D option quiet

dtrace:::BEGIN
{
	interval = $1 ? $1 : 1;
	sec = 0;
	printf("%-20s %10s %10s %10s\n", "TIME", "main/s", "os/s",
	    "syscalls/s");
	main = 0; os = 0; syscalls = 0;
}

pid$target:a.out:main.*:entry    { main++; }
pid$target:a.out:os.*:entry      { os++; }
syscall:::entry /pid == $target/ { syscalls++; }

profile:::tick-1s
/interval && ++sec == interval/
{
	sec = 0;
	printf("%-20Y %10d %10d %10d\n", walltimestamp,
	    main / interval, os / interval, syscalls / interval);
	main = 0; os = 0; syscalls = 0;
}
