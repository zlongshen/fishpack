!
!     file thwsplr.f90
!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 2005 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                    FISHPACK90  Version 1.1                    *
!     *                                                               *
!     *                      A Package of Fortran                     *
!     *                                                               *
!     *                Subroutines and Example Programs               *
!     *                                                               *
!     *               for Modeling Geophysical Processes              *
!     *                                                               *
!     *                             by                                *
!     *                                                               *
!     *        John Adams, Paul Swarztrauber and Roland Sweet         *
!     *                                                               *
!     *                             of                                *
!     *                                                               *
!     *         the National Center for Atmospheric Research          *
!     *                                                               *
!     *                Boulder, Colorado  (80307)  U.S.A.             *
!     *                                                               *
!     *                   which is sponsored by                       *
!     *                                                               *
!     *              the National Science Foundation                  *
!     *                                                               *
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!
!
!     Purpose:
!
!     Program to illustrate the use of subroutine hwsplr to solve
!     the equation
!
!     (1/r)(d/dr)(r*(du/dr)) + (1/r**2)(d/dtheta)(du/dtheta) = 16*r**2
!
!     on the quarter-disk 0 < r < 1, 0 < theta < pi/2 with
!     with the boundary conditions
!
!     u(1, theta) = 1 - cos(4*theta), 0 <= theta <= 1
!
!     and
!
!     (du/dtheta)(r, 0) = (du/dtheta)(r, pi/2) = 0,  0 <= r <= 1.
!
!     (note that the solution u is unspecified at r = 0.)
!          the r-interval will be divided into 50 panels and the
!     theta-interval will be divided into 48 panels.
!
!
!     from dimension statement we get value of idimf.
!
program thwsplr

    use, intrinsic :: ISO_Fortran_env, only: &
        stdout => OUTPUT_UNIT

    use fishpack_library, only: &
        wp, &
        ip, &
        FishpackSolver

    ! Explicit typing only
    implicit none

    !-----------------------------------------------
    ! Dictionary
    !-----------------------------------------------
    type(FishpackSolver)        :: solver
    integer(ip), parameter      :: m = 50
    integer(ip), parameter      :: n = 48
    integer(ip), parameter      :: idimf = 100
    integer(ip)                 :: mbdcnd, nbdcnd, mp1, np1, i, j, ierror
    real(wp), parameter         :: pi = acos(-1.0_wp)
    real(wp)                    :: f(idimf, m)
    real(wp), dimension (m + 1) :: bdc, bdd, r, bda, bdb
    real(wp), dimension (n + 1) :: theta
    real(wp)                    :: a, b, c, d, elmbda
    real(wp)                    :: pertrb, discretization_error, z
    !-----------------------------------------------

    a = 0.0_wp
    b = 1.0_wp
    mbdcnd = 5
    c = 0.0_wp
    d = pi/2
    nbdcnd = 3
    elmbda = 0.0_wp
    !
    !     auxiliary quantities.
    !
    mp1 = m + 1
    np1 = n + 1
    !
    !     generate and store grid points for the purpose of computing
    !     boundary data and the right side of the poisson equation.
    !
    do i = 1, mp1
        r(i) = real(i - 1, kind=wp)/50
    end do

    do j = 1, np1
        theta(j) = real(j - 1, kind=wp)*pi/96
    end do
    !
    !     generate boundary data.
    !
    bdc(:mp1) = 0.0_wp
    bdd(:mp1) = 0.0_wp
    !
    !     bda and bdb are dummy variables.
    !
    do j = 1, np1
        f(mp1, j) = 1.0_wp - cos(4.0_wp*theta(j))
    end do
    !
    !     generate right side of equation.
    !
    do i = 1, m
        f(i, :np1) = 16.0_wp * r(i)**2
    end do

    ! Solve system
    call solver%hwsplr(a, b, m, mbdcnd, bda, bdb, c, d, n, nbdcnd, bdc, bdd, &
        elmbda, f, idimf, pertrb, ierror)
    !
    !     compute discretization error.  the exact solution is
    !                u(r, theta) = (r**4)*(1 - cos(4*theta))
    !
    discretization_error = 0.0_wp
    do i = 1, mp1
        do j = 1, np1
            z = abs(f(i, j)-(r(i)**4)*(1.0_wp-cos(4.0_wp*theta(j))))
            discretization_error = max(z, discretization_error)
        end do
    end do

    !
    !==> Print earlier output from platforms with 64-bit floating point
    !    arithmetic followed by the output from this computer
    !
    write( stdout, '(/a)') '     hwsplr *** TEST RUN *** '
    write( stdout, '(a)') '     Previous 64 bit floating point arithmetic result '
    write( stdout, '(a)') '     ierror = 0,  discretization error = 6.19134e-4'
    write( stdout, '(a)') '     The output from your computer is: '
    write( stdout, '(a,i3,a,1pe15.6/)') &
        '     ierror =', ierror, &
        ' discretization error = ', discretization_error

end program thwsplr