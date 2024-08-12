!                                    _ _                __          _      __ ___   ___
! _ __  _ __ ___  _ __ ___   ___  __| (_) ___  ___     / _| ___ ___| |_   / _/ _ \ / _ \
!| '_ \| '__/ _ \| '_ ` _ \ / _ \/ _` | |/ _ \/ __|   | |_ / __/ __| __| | || (_) | | | |
!| |_) | | | (_) | | | | | |  __/ (_| | | (_) \__ \   |  _| (__\__ \ |_ _|  _\__, | |_| |
!| .__/|_|  \___/|_| |_| |_|\___|\__,_|_|\___/|___/___|_|  \___|___/\__(_)_|   /_/ \___/
!|_|                                             |_____|
!
!   promedios_fcst.f90
!   
!
!   Created by Agustin Garcia on 15/04/15.
!   Copyright 2015 Centro de Ciencias de la Atmosfera, UNAM. All rights reserved.
!
!   Lee salidas de la integracion en la vertical, y guarda por hora y compuesto
!   los valores obtenidos. esto se realiza hasta la capa de mezclado.
!
!   10-04-2015 Inclusion de PBL, Ozone
!
!   ifort -O3  promedios_fcst.f90 -o prom_fct.exe
program promedios
implicit none

integer :: n_compounds, n_times
parameter (n_compounds=4, n_times=3) !compuestos 3 y PBL, tiempos 10,15 y 16 hrs
character (len=25) ::header,cdum
character (len=18) ::fname
character (len=3),Dimension(n_times):: var
character (len=2),Dimension(12):: mes
real,allocatable  :: lon(:),lat(:),pblh(:),so2(:,:),no2(:,:),co(:,:),o3(:,:)
integer,Dimension(12)::ndays
character (len=2),Dimension(n_times)::hora
integer i,icont,ndat,j,im,mday,ih

data mes/'09','10','11','04','05','06' ,&
&        '07','08','01','02','03','12'/

data ndays/30,31,30,30,31,30,31,31,31,28,31,31/
data hora /"16","20","21"/
ndat= 19584!400!38192
mday=31

allocate(lon(ndat),lat(ndat),so2(ndat,mday),no2(ndat,mday),co(ndat,mday))
allocate(pblh(ndat),o3(ndat,mday))

do im = 1,12
SO2=-999
NO2=-999
CO=-999
O3=-999
pblh=-999
do ih=1,n_times
  do i=1,ndays(im)
    fname=mes(im)//'00'//"-"//hora(ih)//"_pron.txt"
    write(fname(3:4),"(I2.2)") i
    if(i.eq.1) print *,fname
    open (unit=10,file=fname,READONLY,ERR=333)
    read (10,'(A)') header
    do icont=1,ndat
      read(10,*) lon(icont),lat(icont),so2(icont,i),no2(icont,i),co(icont,i),o3(icont,i),pblh(icont)
    end do !icont
333 continue
  end do
  close(10)
  open (20,file=mes(im)//'_'//hora(ih)//'_SO2.csv')
  open (21,file=mes(im)//'_'//hora(ih)//'_CO.csv')
  open (22,file=mes(im)//'_'//hora(ih)//'_NO2.csv')
  open (23,file=mes(im)//'_'//hora(ih)//'_O3.csv')
  write(20,*)'Lon, lat,pbl, SO2'
  write(21,*)'Lon, lat,pbl, CO'
  write(22,*)'Lon, lat,pbl,  NO2'
  write(23,*)'Lon, lat,pbl, Ozone'
do i=1,ndat
    write(20,100)lon(i),lat(i),pblh(i),(so2(i,j),j=1,ndays(im))
    write(21,100)lon(i),lat(i),pblh(i),(co(i,j),j=1,ndays(im))
    write(22,100)lon(i),lat(i),pblh(i),(no2(i,j),j=1,ndays(im))
    write(23,100)lon(i),lat(i),pblh(i),(o3(i,j),j=1,ndays(im))
  end do
end do ! ih
end do !im
100 format(f9.3,",",f9.3,",",f6.1,",",31(ES11.3,","))
end program
