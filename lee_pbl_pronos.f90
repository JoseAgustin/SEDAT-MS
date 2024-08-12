!  _                      _     _                                         __ ___   ___
! | | ___  ___      _ __ | |__ | |     _ __  _ __ ___  _ __   ___  ___   / _/ _ \ / _ \
! | |/ _ \/ _ \    | '_ \| '_ \| |    | '_ \| '__/ _ \| '_ \ / _ \/ __| | || (_) | | | |
! | |  __/  __/    | |_) | |_) | |    | |_) | | | (_) | | | | (_) \__ \_|  _\__, | |_| |
! |_|\___|\___|____| .__/|_.__/|_|____| .__/|_|  \___/|_| |_|\___/|___(_)_|   /_/ \___/
!            |_____|_|          |_____|_|
!
!    Programa para leer capas  y hacer la integración en la vertical hasta la pbl.
!   
!    Jose Agustin Garcia Reynoso
!    Centro de Ciencias de la Atmosfera
!
!   ifort -O3 lee_pbl_pronos.f90 -o lee_pbl_p.exe
!
      program lee_capas
      implicit none
      integer :: i,j,ii
      integer :: nlevs,nlevs2,nx,ny,nxy,nvert,nf
!      parameter (nx= 20,ny=20,nxy=nx*ny,nvert=29,nf=4) ! Ecacor
       parameter (nx=144,ny=136,nxy=nx*ny,nvert=29,nf=5) ! Mexico
      integer :: iunit=10, ounit=60, hora
      real,dimension(nxy) ::  dvar,lat,lon, pbl,altura
      real,dimension(nxy,nvert,nf) ::  variable
      real,dimension(nxy,nf) :: suma
      character(len=9),dimension (nf) :: cfile

     data cfile /'capas.dat','c_so2.dat','c_no2.dat',' c_co.dat',' c_o3.dat'/
!
      ! lee  datos
      suma = 0.00
      open(unit=iunit,file='c_pblh.dat',ACCESS='sequential',&
     &     status='old',action='read',convert='big_endian', &
     &     form='unformatted')
      read(iunit,END=125) pbl
 125  close(iunit)
      do ii=1,nf
      print *,'lee ',cfile(ii)
      open(unit=iunit,file=cfile(ii),ACCESS='sequential',&
     &     status='old',action='read',convert='big_endian', &
     &     form='unformatted')
        do i=1,nvert
        read(iunit,END=100) dvar
        do j=1,nxy
        variable(j,i,ii)=dvar(j)
        end do !nxy
       end do !nvert
 100   close(iunit)
       if(ii.ge.2) then
        do i=1,nvert
           altura=0.0
         do j=1,nxy
          altura(j)=altura(j)+variable(j,i,1)
          if(altura(j).le.pbl(j)) then
          suma(j,ii)= suma(j,ii) + variable(j,i,1)*100* variable(j,i,ii) !conversion m to cm 100
          else
            exit
          end if
         end do
        end do
       end if
       end do
      open(unit=iunit,file='d_lat.dat',ACCESS='sequential',&
     &     status='old',action='read',convert='big_endian', &
     &     form='unformatted')
     read(iunit,END=110) lat
110  close(iunit)
       open(unit=iunit,file='d_lon.dat',ACCESS='sequential',&
     &     status='old',action='read',convert='big_endian', &
     &     form='unformatted')
     read(iunit,END=120) lon
120  close(iunit)

      open (ounit,file='conc2.txt')
      write(60,'(a)') 'Lon, Lat, SO2, NO2, CO,  O3, pbl'
      do i=1,nxy
        write(60,200) lon(i),lat(i),suma(i,2),suma(i,3),suma(i,4),suma(i,5),pbl(i)
      end do
200  format(f11.5,",",f11.5,",",ES14.7,",",ES14.7,",",ES14.7,",",ES14.7,",",f11.5)
      end program
