#!/usr/sbin/dtrace -s
/*
 * go_stat.d	go status tool
 *
 * USAGE: go_stat.d -p PID [interval]
 *
 * COLUMNS:
 * 
 * 	main		main package functions
 * 	syscalls	system calls
 * 	TU%CPU		total percent CPU in user-mode
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
	printf("%-20s %10s %10s %10s\n", "TIME", "main/s", "syscalls/s",
	    "TU%CPU");
	main = 0; syscalls = 0; oncpu = 0;
}

pid$target:a.out:main.*:entry        { main++; }
syscall:::entry /pid == $target/     { syscalls++; }
profile-100 /arg1 && pid == $target/ { oncpu++; }

profile:::tick-1s
/interval && ++sec == interval/
{
	sec = 0;
	printf("%-20Y %10d %10d %10d\n", walltimestamp,
	    main / interval, syscalls / interval, oncpu / interval);
	main = 0; syscalls = 0; oncpu = 0;
}
