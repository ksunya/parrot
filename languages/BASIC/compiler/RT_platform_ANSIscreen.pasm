.const int BLACK =  0
.const int RED	=  1
.const int GREEN  = 2
.const int YELLOW = 3
.const int BLUE   = 4
.const int MAGENTA= 5
.const int CYAN   = 6
.const int WHITE  = 7
.sub _ansi_setup
	saveall
	$P0=new PerlArray
	set $P0[0], BLACK
	set $P0[1], BLUE
	set $P0[2], GREEN
	set $P0[3], CYAN
	set $P0[4], RED
	set $P0[5], MAGENTA
	set $P0[6], YELLOW
	set $P0[7], WHITE
	store_global "ANSI_fgcolors", $P0

	$P0=new PerlArray
	set $P0[0], BLACK
	set $P0[1], BLUE
	set $P0[2], GREEN
	set $P0[3], CYAN
	set $P0[4], RED
	set $P0[5], MAGENTA
	set $P0[6], YELLOW
	set $P0[7], WHITE
	set $P0[8], BLACK
	set $P0[9], BLUE
	set $P0[10], GREEN
	set $P0[11], CYAN
	set $P0[12], RED
	set $P0[13], MAGENTA
	set $P0[14], YELLOW
	set $P0[15], 8
	store_global "ANSI_bgcolors", $P0

	$P0=new PerlHash
	$P0["value"]=0
	store_global "scankey", $P0

	restoreall
	ret
.end
.sub _ansi_screen_clear
	print "\e[2J"
	print "\e[H"
	ret
.end
.sub _ansi_shutdown
	call _TERMIO_normal
	ret
.end
.sub _ANSI_SCREEN_LOCATE	# void ansi_screen_locate (int x, int y)
	saveall
	.param int x
	.param int y
	print "\e["
	print x
	print ";"
	print y
	print "H"
	restoreall
	ret
.end
## These don't work exactly right.  ANSI would require that I send
## \e[6n and read the input stream for a \e[row;colR reply from the 
## terminal.  I *really* can't do that until IO is fixed, because STDIN
## is line-buffered and asking the user to press return after each cursor
## positioning is lame.
#ANSI_SCREEN_SETXCUR:
#	print "\e[;"
#	print I1
#	print "H"
#	ret
#
#ANSI_SCREEN_SETYCUR:
#	print "\e["
#	print I1
#	print ";H"
#	ret
#
#	# I0,I1
#	# QB origin is 1,1

## QB.exe
##     0 = black       4 = red           8 = grey             12 = light red
##     1 = blue        5 = magenta       9 = light blue       13 = light magenta
##     2 = green       6 = brown        10 = light green      14 = yellow
##     3 = cyan        7 = white        11 = light cyan       15 = bright white
#
.sub _ANSI_SCREEN_COLOR		#  void ansi_screen_color(int fg, int bg)
	saveall
	.param int fore
	.param int back
	print "\e"
#	# foreground in I0
#	# background in I1
	print "[0;"
	find_global $P0, "ANSI_fgcolors"
	lt fore, 8, ANSI_FG
	sub fore, fore, 8
	print "1;"	# Turn on high intensity
ANSI_FG: set $I3, $P0[fore]
	print "3"
	print $I3
	print ";"
	
	# Background
ANSI_BG:find_global $P0, "ANSI_bgcolors"
	set $I3, $P0[back]
	print "4"
	print $I3
	print "m"
	restoreall
	ret
.end
.sub _set_noecho_cbreak
	saveall
	loadlib P1, ""
	dlfunc P0, P1, "ioctl", "iiip"
	set I0, 1
	P9 = new ManagedStruct	# Saved
	P10 = new ManagedStruct   # New
	set P9, 20	# sizeof termio 4/byte aligned
	set P10, 20
	set I5, 0
	set I6, 0x5405  # TCGETA
	set P5, P9
	invoke		# ioctl(0, TCGETA, &savetty);
	set I5, 0
	set I6, 0x5405
	set P5, P10
	invoke		# ioctl(0, TCGETA, &settty);
	.arg 2
	.arg 6
	.arg P10
	call _get_little_endian
	.result I0
	set I1, 2	# ICANON
	bnot I1, I1 	# ~ICANON
	band I0, I0, I1 # settty.c_lflag &= ~ICANON;
	set I1, 8	# IECHO
	bnot I1, I1 	# ~ICANON
	band I0, I0, I1	# settty.c_lflag &= ~ECHO;
	.arg I0
	.arg 2
	.arg 6
	.arg P10
	call _set_little_endian
	set I5, 0
	set I6, 0x5408
	set P5, P10
	invoke		# ioctl(0, TCSETAF, &settty);
	store_global "ioctl_mode", P9
	restoreall
	ret
.end
.sub _set_echo_nocbreak
	saveall	
	loadlib P1, ""
	dlfunc P0, P1, "ioctl", "iiip"
	find_global P9, "ioctl_mode"
	set I5, 0
	set I6, 0x5408
	set P5, P9
	invoke		# ioctl(0, TCSETAF, &savetty)
	restoreall
	ret
.end

.sub _set_nonblock	# void _set_nonblock
	saveall
	set I11, 0
	loadlib P1, ""
	dlfunc P0, P1, "fcntl", "iiii"
	set I0, 1
	set I5, 0	# Stdin
	set I6, 3	# F_GETFL
	invoke		# mode=fcntl(0, F_GETFL, unused)

	set I11, I5	# Old values
	dlfunc P0, P1, "fcntl", "iiil"
	bor I7, I5, 2048  # O_NONBLOCK 04000
	set I5, 0	# Stdin
	set I6, 4	# F_SETFL
	invoke		# nmode=fcntl(0, F_SETFL, mode | O_NONBLOCK)

	$P0=new PerlHash
	set $P0["value"], I11
	store_global "fcntl_mode", $P0
	restoreall
	ret
.end
.sub _unset_nonblock	# void _unset_nonblock
	saveall
	find_global P0, "fcntl_mode"
	set I11, P0["value"]
	loadlib P1, ""
	dlfunc P0, P1, "fcntl", "iiil"
	set I7, I11
	set I5, 0
	set I6, 4
	invoke		# nmode=fcntl(0, F_SETFL, mode)
	restoreall
	ret
.end
.sub _TERMIO_scankey
	saveall
	find_global $P0, "scankey"
	set I0, $P0["value"]
	eq I0, 1, END
        #call _set_nonblock
	call _set_noecho_cbreak
END:    set $P0["value"], 1
	store_global "scankey", $P0
	restoreall
	ret
.end
.sub _TERMIO_normal
	saveall
	find_global $P0, "scankey"
	set I0, $P0["value"]
	eq I0, 0, END
	#call _unset_nonblock
	call _set_echo_nocbreak
END:    set $P0["value"], 0
	store_global "scankey", $P0
	restoreall
	ret
.end

# For now, uses TERMIO calls directly and assumes you're on a
# LITTLE ENDIAN machine.
.sub _TERMIO_INKEY
	saveall

	read $S0, 1

	.return $S0
	restoreall
	ret
.end

