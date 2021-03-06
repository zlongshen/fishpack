!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 2005 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                         Fishpack                              *
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
! Purpose
!
!     program to illustrate the use of subroutine cmgnbn to solve
!     the equation
!
!     (1+x)**2*(d/dx)(du/dx) - 2(1+x)(du/dx) + (d/dy)(du/dy)
!
!             - sqrt(-1)*u = (3 - sqrt(-1))*(1+x)**4*sin(y)         (1)
!
!     on the rectangle 0 < x < 1 and -pi < y < pi
!     with the boundary conditions
!
!     (du/dx)(0, y) = 4sin(y)                               (2)
!                                -pi <= y <= pi
!     u(1, y) = 16sin(y)                                    (3)
!
!     and with u periodic in y using finite differences on a
!     grid with deltax (= dx) = 1/20 and deltay (= dy) = pi/20.
!        to set up the finite difference equations we define
!     the grid points
!
!     x(i) = (i-1)dx            i=1, 2, ..., 21
!
!     y(j) = -pi + (j-1)dy      j=1, 2, ..., 41
!
!     and let v(i, j) be an approximation to u(x(i), y(j)).
!     numbering the grid points in this fashion gives the set
!     of unknowns as v(i, j) for i=1, 2, ..., 20 and j=1, 2, ..., 40.
!     hence, in the program m = 20 and n = 40.  at the interior
!     grid point (x(i), y(j)), we replace all derivatives in
!     equation (1) by second order central finite differences,
!     multiply by dy**2, and collect coefficients of v(i, j) to
!     get the finite difference equation
!
!     a(i)v(i-1, j) + b(i)v(i, j) + c(i)v(i+1, j)
!
!     + v(i, j-1) - 2v(i, j) + v(i, j+1) = f(i, j)            (4)
!
!     where s = (dy/dx)**2, and for i=2, 3, ..., 19
!
!     a(i) = (1+x(i))**2*s + (1+x(i))*s*dx
!
!     b(i) = -2(1+x(i))**2*s - sqrt(-1)*(dy**2)
!
!     c(i) = (1+x(i))**2*s - (1+x(i))*s*dx
!
!     f(i, j) = (3 - sqrt(-1))*(1+x(i))**4*(dy**2)*sin(y(j))
!              for j=1, 2, ..., 40.
!
!        to obtain equations for i = 1, we replace the
!     derivative in equation (2) by a second order central
!     finite difference approximation, use this equation to
!     eliminate the virtual unknown v(0, j) in equation (4)
!     and arrive at the equation
!
!     b(1)v(1, j) + c(1)v(2, j) + v(1, j-1) - 2v(1, j) + v(1, j+1)
!
!                       = f(1, j)
!
!     where
!
!     b(1) = -2s - sqrt(-1)*(dy**2) , c(1) = 2s
!
!     f(1, j) = (11-sqrt(-1)+8/dx)*(dy**2)*sin(y(j)),  j=1, 2, ..., 40.
!
!     for completeness, we set a(1) = 0.
!        to obtain equations for i = 20, we incorporate
!     equation (3) into equation (4) by setting
!
!     v(21, j) = 16sin(y(j))
!
!     and arrive at the equation
!
!     a(20)v(19, j) + b(20)v(20, j)
!
!     + v(20, j-1) - 2v(20, j) + v(20, j+1) = f(20, j)
!
!     where
!
!     a(20) = (1+x(m))**2*s + (1+x(m))*s*dx
!
!     b(20) = -2*(1+x(m))**2*s - sqrt(-1)*(dy**2)
!
!     f(20, j) = ((3-sqrt(-1))*(1+x(m))**4*(dy**2) - 16(1+x(m))**2*s
!                + 16(1+x(m))*s*dx)*sin(y(j))
!
!                    for j=1, 2, ..., 40.
!
!     for completeness, we set c(20) = 0.  hence, in the
!     program mperod = 1.
!        the periodicity condition on u gives the conditions
!
!     v(i, 0) = v(i, 40) and v(i, 41) = v(i, 1) for i=1, 2, ..., 20.
!
!     hence, in the program nperod = 0.
!
!          the exact solution to this problem is
!
!                  u(x, y) = (1+x)**4*sin(y) .
!
!
!     from the dimension statement we get that idimf = 22
!
program test_cmgnbn

    use, intrinsic :: ISO_Fortran_env, only: &
        stdout => OUTPUT_UNIT

    use fishpack

    ! Explicit typing only
    implicit none

    ! Dictionary
    integer(ip), parameter    :: M = 20, N = 40
    integer(ip), parameter    :: MP1 = M + 1, NP1 = N + 1
    integer(ip), parameter    :: IDIMF = M + 2
    integer(ip)               :: mperod, nperod, i, j, ierror
    real(wp)                  :: dx, dy, x(MP1), y(NP1)
    real(wp), parameter       :: ZERO = 0.0_wp, ONE = 1.0_wp, TWO = 2.0_wp
    complex(wp)               :: f(IDIMF, N)
    complex(wp), dimension(M) :: a, b, c

    ! Set boundary conditions
    mperod = 1
    nperod = 0

    ! Set mesh sizes
    dx = ONE/M
    dy = TWO_PI/N

    ! Generate grid points for later use.
    do i = 1, MP1
        x(i) = real(i - 1, kind=wp) * dx
    end do

    do j = 1, NP1
        y(j) = -PI + real(j - 1, kind=wp) * dy
    end do

    ! Generate coefficients.
    block
        real(wp)               :: s, dy2, t, t2
        complex(wp), parameter :: IMAGINARY_UNIT = (ZERO, ONE)

        s = (dy/dx)**2
        dy2 = dy**2
        do i = 2, M - 1
            t = ONE + x(i)
            t2 = t**2
            a(i) = cmplx((t2 + t * dx) * s, ZERO, kind=wp)
            b(i) = -TWO * t2 * s - IMAGINARY_UNIT * dy2
            c(i) = cmplx((t2 - t * dx) * s, ZERO, kind=wp)
        end do
        a(1) = ZERO
        b(1) = -TWO * s - IMAGINARY_UNIT * dy2
        c(1) = cmplx(TWO * s, ZERO, kind=wp)
        b(M) = (-TWO * s * (ONE + x(M))**2) - IMAGINARY_UNIT * dy2
        a(M) = cmplx(s * (ONE + x(M))**2 + (ONE + x(M)) * dx * s, ZERO, kind=wp)
        c(M) = ZERO
    end block

    ! Generate right hand side
    block
        real(wp)            :: s, dy2, t, t2, t4
        real(wp), parameter :: THREE = 3.0_wp, EIGHT = 8.0_wp
        real(wp), parameter :: ELEVEN = 11.0_wp, SIXTEEN = 16.0_wp

        s = (dy/dx)**2
        dy2 = dy**2
        do i = 2, M - 1
            do j = 1, N
                f(i, j) = cmplx(THREE, -ONE, kind=wp) * ((ONE + x(i))**4) * dy2 * sin(y(j))
            end do
        end do

        t = ONE + x(M)
        t2 = t**2
        t4 = t**4
        do j = 1, N
            f(1, j) = (cmplx(ELEVEN, -ONE, kind=wp) + EIGHT/dx) * dy2 * sin(y(j))
            f(M, j) = (cmplx(THREE, -ONE, kind=wp) * t4 * dy2 &
                -SIXTEEN * t2 * s + SIXTEEN * t * s * dx) * sin(y(j))
        end do
    end block

    ! Solve complex linear system
    call cmgnbn(nperod, N, mperod, M, a, b, c, IDIMF, f, ierror)

    ! Compute discretization error. The exact solution is
    !
    ! u(x, y) = (1+x)**4*sin(y).
    !
    block
        real(wp), parameter :: KNOWN_ERROR = 0.916199590891393e-2_wp
        real(wp)    :: discretization_error
        complex(wp) :: exact_solution(M,N)

        do i = 1, M
            do j = 1, N
                exact_solution(i,j) = ((ONE + x(i))**4) * sin(y(j))
            end do
        end do

        ! Set discretization error
        discretization_error = maxval(abs(exact_solution - f(:M,:N)))

        call check_output('cmgnbn', ierror, KNOWN_ERROR, discretization_error)
    end block

end program test_cmgnbn
