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
 * 	runtime		runtime package functions
 * 	other		other go functions (not in prev columns)
 * 	syscalls	system calls
 *
 * If an interval is not provided, this defaults to 1 second.
 */

#pragma D option defaultargs
#pragma D option quiet

dtrace:::BEGIN
{
	interval = $1 ? $1 : 1;
	sec = 0;
	printf("%-20s %10s %10s %10s %10s %10s\n", "TIME", "main/s", "os/s",
	    "runtime/s", "other/s", "syscalls/s");
	main = 0; os = 0; runtime = 0; other = 0; syscalls = 0;
}

pid$target:a.out:main.*:entry    { main++; }
pid$target:a.out:os.*:entry      { os++; }
pid$target:a.out:runtime.*:entry { runtime++; }
pid$target:a.out::entry          { other++; }
syscall:::entry /pid == $target/ { syscalls++; }

profile:::tick-1s
/interval && ++sec == interval/
{
	other = other - main - os - runtime;
	sec = 0;
	printf("%-20Y %10d %10d %10d %10d %10d\n", walltimestamp,
	    main / interval, os / interval, runtime / interval,
	    other / interval, syscalls / interval);
	main = 0; os = 0; runtime = 0; other = 0; syscalls = 0;
}
