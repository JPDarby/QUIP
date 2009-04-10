program md
  use libAtoms_module

  implicit none

  real(dp), parameter :: dt = 1.0_dp  ! Time step
  real(dp), parameter :: init_temp = 300.0_dp

  type(DynamicalSystem) :: ds
  type(Atoms)           :: at, tmpat
  type(inoutput)        :: movie
  real(dp), allocatable :: f(:,:)
  real(dp)              :: Q
  integer               :: n

  call system_initialise
  call initialise(movie, "movie.xyz", action=OUTPUT)
  call diamond(tmpat, 3.5_dp)
  call supercell(at, tmpat, 2, 2, 2)
  call set_atoms(at, 6)
  allocate(f(3,at%N)) ! Allocate force array

  call atoms_set_cutoff(at,3.0_dp)
  call calc_connect(at)
  call calc_dists(at)
  call initialise(ds, at)
  call rescale_velo(ds, init_temp)
  call zero_momentum(ds)


  Q = nose_hoover_mass(Ndof = 3*ds%N, T = init_temp, tau = 1000.0_dp) ! This 'tau' is the characteristic time of your system, 
                                                                      ! e.g. from phonon spectrum, and controls the coupling
                                                                      ! of the thermostat to the system:
                                                                      ! higher tau = higher mass = lower coupling

  call add_thermostat(ds, NOSE_HOOVER_LANGEVIN, init_temp, Q = Q, tau = 5000.0_dp) ! This tau controls how fast the nose-hoover variable
                                                                                   ! explores phase space.
                                                                                   ! higher tau = slower, and more Nose-Hoover like.

!  call add_thermostat(ds, NOSE_HOOVER, init_temp, Q = Q)
!  call add_thermostat(ds, LANGEVIN, init_temp, tau = 1000.0_dp)

  ! Use random forces
  f = 0.0_dp
  call randomise(f, 0.1_dp) 
  call zero_sum(f)

  do n = 1, 1000
     call ds_print_status(ds, 'M')
     if(mod(n, 20) == 0) then
        call print_xyz(ds%atoms,movie)
        call calc_connect(ds%atoms)
     end if

     call advance_verlet1(ds, dt, f)

     !Calculate new forces
     f = 0.0_dp
     call randomise(f, 0.1_dp) 
     call zero_sum(f)

     call advance_verlet2(ds, dt, f)

  end do

  call finalise(at)
  call finalise(ds)
  call finalise(movie)
  deallocate(f)

  call system_finalise()
end program md
