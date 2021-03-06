program testTime_prg
	!! Test program for time_mod
	use time_mod
	implicit none
	
	call testCpuTime
	call testWallTime
	
contains

	subroutine testCpuTime
		!! Test cpuTime to verify operation
		real(wp)::t0,t1
		
		t0 = cpuTime()
		call wait(0.1_wp)
		t1 = cpuTime()
		
		if( t1-t0>0.01_wp ) error stop "Failed cpuTime check"
	end subroutine testCpuTime 

	subroutine testWallTime
		!! Test wallTime to verify operation
		real(wp)::t0,t1
		
		t0 = wallTime()
		call wait(0.1_wp)
		t1 = wallTime()
		
		if( t1-t0<0.1_wp ) error stop "Failed wallTime check"
	end subroutine testWallTime 

end program testTime_prg
