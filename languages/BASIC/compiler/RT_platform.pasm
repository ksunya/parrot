.include "RT_platform_win32.pasm"
.include "RT_platform_ANSIscreen.pasm"
.sub _platform_setup		# void platform_setup(void)
	saveall
	sysinfo S0, 4
	ne S0, "MSWin32", NOTWIN
	call _win32_setup
	branch END
NOTWIN: call _ansi_setup
END:	restoreall
	ret
.end
.sub _platform_shutdown
	saveall
	sysinfo S0, 4
	ne S0, "MSWin32", NOTWIN
	call _win32_shutdown
	branch END
NOTWIN: call _ansi_shutdown
END:	restoreall
	ret
.end
.sub _screen_clear
	saveall
	find_global $P0, "PRINTCOL"
	set $P0["value"], 0
	store_global "PRINTCOL", $P0
	sysinfo S0, 4
	ne S0, "MSWin32", NOTWIN
	call _win32_screen_clear
	branch END
NOTWIN: call _ansi_screen_clear
END:	restoreall
	ret
.end

#SCREEN_SETXCUR:
#	set I1, P6[.VALUE]
#	sysinfo S0, 4
#	eq S0, "MSWin32", WIN32_SCREEN_SETXCUR
#	branch ANSI_SCREEN_SETXCUR
#
#SCREEN_SETYCUR:
#	set I1, P6[.VALUE]
#	sysinfo S0, 4
#	eq S0, "MSWin32", WIN32_SCREEN_SETYCUR
#	branch ANSI_SCREEN_SETYCUR
#
#	# X in P7, Y in P6
.sub _screen_locate		# void screen_locate(float x, float y)
	saveall
	.param float xf
	.param float yf
	.local int x
	.local int y
	.local string sys
	set x, xf
	set y, yf
	sysinfo sys, 4

	.arg y
	.arg x
	ne sys, "MSWin32", NOTWIN
	call _WIN32_SCREEN_LOCATE
	branch END
NOTWIN: call _ANSI_SCREEN_LOCATE
END:	restoreall
	ret
.end
.sub _screen_color	# void screen_color(float fore, float back)
	saveall
	.param float foref
	.param float backf
	.local int fore
	.local int back
	.local string sys
	set back, backf
	set fore, foref
	.arg back
	.arg fore
	sysinfo sys, 4
	ne sys, "MSWin32", NOTWIN
	call _WIN32_SCREEN_COLOR
	branch END
NOTWIN: call _ANSI_SCREEN_COLOR
END:	restoreall
	ret
.end

.sub _line_read
	saveall
	.local string sys
	sysinfo sys, 4
	eq sys, "MSWin32", END
	call _TERMIO_normal
END:	restoreall
	ret
.end
.sub _scan_read
	saveall
	.local string sys
	sysinfo sys, 4
	eq sys, "MSWin32", END
	call _TERMIO_scankey
END:	restoreall
	ret
.end

.sub _inkey_string		# string inkey$(void)
	saveall
	.local string sys
	sysinfo sys, 4
	ne sys, "MSWin32", NOTWIN
	call _WIN32_INKEY
	branch END
NOTWIN: call _TERMIO_INKEY
END:	restoreall
	ret
.end
