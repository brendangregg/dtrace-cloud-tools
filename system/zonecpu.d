#!/usr/sbin/dtrace -s
/*
 * zonecpu.d    Lightweight CPU usage sample by-zone and by-app.
 *
 * USAGE: zonecpu.d [interval]
 *
 * For use when "prstat -Z" is too slow/heavyweight/laggy.
 *
 * SEE ALSO: zonetop.d
 *
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at http://smartos.org/CDDL
 *
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file.
 *
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 *
 * Copyright (c) 2012 Joyent Inc., All rights reserved.
 * Copyright (c) 2012 Brendan Gregg, All rights reserved.
 */

#pragma D option quiet
#pragma D option bufsize=32k
#pragma D option aggsize=32k
#pragma D option dynvarsize=32k
#pragma D option defaultargs

dtrace:::BEGIN
{
	interval = $1 ? $1 : 1;
	printf("Sampling CPU users @97 Hertz, output each %d sec...\n",
	    interval);
	secs = interval;
}

profile:::profile-97
/arg0/
{
	@zone_sys[zonename] = count();
	@app_sys[execname] = count();
	@sys = count();
}

profile:::profile-97
/arg1/
{
	@zone_usr[zonename] = count();
	@app_usr[execname] = count();
	@usr = count();
}

profile:::tick-1s
{
	secs--;
}

profile:::tick-1s
/secs == 0/
{
	normalize(@usr, interval);
	normalize(@sys, interval);
	normalize(@zone_usr, interval);
	normalize(@zone_sys, interval);
	normalize(@app_usr, interval);
	normalize(@app_sys, interval);
	printf("\n\n%Y (total usr, sys): ", walltimestamp);
	printa("%@8d %@8d\n", @usr, @sys);
	printf("\nZones @97 Hertz (usr, sys):\n");
	printa("   %-35s %@8d %@8d\n", @zone_usr, @zone_sys);
	printf("\nProcesses @97 Hertz (usr, sys):\n");
	printa("   %-35s %@8d %@8d\n", @app_usr, @app_sys);
	trunc(@usr); trunc(@sys);
	trunc(@zone_usr); trunc(@zone_sys);
	trunc(@app_usr); trunc(@app_sys);
	secs = interval;
}

dtrace:::END
{
	trunc(@usr); trunc(@sys);
	trunc(@zone_usr); trunc(@zone_sys);
	trunc(@app_usr); trunc(@app_sys);
}
