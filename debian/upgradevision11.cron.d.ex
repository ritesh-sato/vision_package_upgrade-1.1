#
# Regular cron jobs for the upgradevision11 package
#
0 4	* * *	root	[ -x /usr/bin/upgradevision11_maintenance ] && /usr/bin/upgradevision11_maintenance
