These are some DTrace tools I've written while debugging performance issues on a SmartOS-based SmartDataCenter (SDC) cloud. SmartOS is based on the illumos-kernel, which is Solaris based. These scripts are not supported.

The smartmachine directory links to scripts that work within a SmartMachine. All other directories are intended for operators of the cloud to execute from the compute node (global zone).

Scripts have a suffix to describe where they execute. "_sdc5" and "_sdc6" describe different SDC versions, SDC5 was based on an OpenSolaris kernel, and SDC6 on the illumos kernel.
