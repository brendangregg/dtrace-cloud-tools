#!/usr/sbin/dtrace -s
/*
 * zonetop.d    Lightweight zone CPU usage.
 *
 * USAGE: zonetop.d zonename
 *
 * For use when "prstat -z" is too slow/heavyweight/laggy.
 *
 * SEE ALSO: zonecpu.d
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
/$$1 == ""/
{
	printf("USAGE: zonetop.d zonename\n");
	exit(1);
}

dtrace:::BEGIN
{
	printf("Sampling zone %s at 97 Hertz...\n", $$1);
}

profile:::profile-97
/arg0 && zonename == $$1/
{
	@app_sys[execname] = count();
}

profile:::profile-97
/arg1 && zonename == $$1/
{
	@app_usr[execname] = count();
}

profile:::tick-1s
{
	printf("\n%Y: processes @97 Hz (usr, sys):\n",
	    walltimestamp);
	printa("   %-44s %@8d %@8d\n", @app_usr, @app_sys);
}

profile:::tick-1s,
dtrace:::END
{
        trunc(@app_usr); trunc(@app_sys);
}
