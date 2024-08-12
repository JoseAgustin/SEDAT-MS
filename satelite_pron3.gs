*           _       _   _                                  _____
* ___  __ _| |_ ___| (_) |_ ___      _ __  _ __ ___  _ __ |___ /  __ _ ___
*/ __|/ _` | __/ _ \ | | __/ _ \    | '_ \| '__/ _ \| '_ \  |_ \ / _` / __|
*\__ \ (_| | ||  __/ | | ||  __/    | |_) | | | (_) | | | |___) | (_| \__ \
*|___/\__,_|\__\___|_|_|\__\___|____| .__/|_|  \___/|_| |_|____(_)__, |___/
*                             |_____|_|                          |___/
* Extrae los datos del WRF en la vertical para la hora 10 del modelo (16:00 hr local)
* genera los archivos: capas.dat d_lat.dat d_lon.dat c_pblh.dat
*                      c_so2.dat c_no2.dat c_co.dat c_o3.dat
'reinit'
say open pronos_W.ctl
'open pronos_W.ctl'
*'set lat 18.6963 20.2909';'set lon -100.001 -98.2036'
'set x  12 155';'set y 12 147'
hora.1=24+10
hora.2=24+9
hora.3=24+10
*
z.1= 1 ;z.16=16
z.2=2  ;z.17=17
z.3=3  ;z.18=18
z.4=4  ;z.19=19
z.5=5  ;z.20=20
z.6=6  ;z.21=21
z.7=7  ;z.22=22
z.8=8  ;z.23=23
z.9=9  ;z.24=24
z.10=10;z.25=25
z.11=11;z.26=26
z.12=12;z.27=27
z.13=13;z.28=28
z.14=14;z.29=29
z.15=15;z.30=30
i=1
tiempo = 1
'set t 'tiempo
'q dims'
say result
'set gxout fwrite '
while (tiempo <2)
'set t  'hora.tiempo
while(i<31)
h.i=' (ph(z='z.i')+phb(z='z.i'))/9.81'
i=i+1
* de altura
endwhile
i=1
while(i<29)
j=i+1
if(i=1)
'set fwrite -be -sq -cl capas.dat'
else
'set fwrite -be -sq -ap capas.dat'
endif
 capa.i = '('h.j' -' h.i')'
 'd 'h.j' -' h.i')'
'disable fwrite'
i=i+1
*de capa
tiempo=tiempo+1
endwhile
* De tiempo
endwhile 
'set gxout shaded'
'd 'capa.1
'close 1'
*
*   Calculo de concentraciones
*
'clear'
'open pronos_M.ctl'
*'set lat 18.6963 20.2909';'set lon -100.001 -98.2036'
'set x  12 155';'set y 12 147'
'set gxout fwrite '
*  Guarda lat
'set fwrite -be -sq -cl d_lat.dat'
'd xlat'
'disable fwrite'
*  Guarda lon
'set fwrite -be -sq -cl d_lon.dat'
'd xlong'
'disable fwrite'
*
tiempo = 1
'set t 'hora.tiempo
i=1
* Avogadro molec/mol
Av=6.023E23
* mL atm/K mgmol
R= 82.057
*
while(tiempo<2)
while(i<29)
*  Referece pression 101352 Pa
 pres = '(p(z='z.i')+pb(z='z.i'))/101325'
 ff = 'pow('pres',0.2854)'
 TK = '(T(z='z.i')+300) * 'ff
if(i=1)
'set fwrite -be -sq -cl c_so2.dat'
else
'set fwrite -be -sq -ap c_so2.dat'
endif
'd so2(z='z.i')*'Av'/'TK'*'pres'/'R'/'1000000
'disable fwrite'
'set gxout fwrite '
if(i=1)
'set fwrite -be -sq -cl c_co.dat'
else
'set fwrite -be -sq -ap c_co.dat'
endif
'd co(z='z.i')*'Av'/'TK'*'pres'/'R'/'1000000
'disable fwrite'
if(i=1)
'set fwrite -be -sq -cl c_no2.dat'
else
'set fwrite -be -sq -ap c_no2.dat'
endif
'd no2(z='z.i')*'Av'/'TK'*'pres'/'R'/'1000000
'disable fwrite'
if(i=1)
'set fwrite -be -sq -cl c_o3.dat'
else
'set fwrite -be -sq -ap c_o3.dat'
endif
'd o3(z='z.i')*'Av'/'TK'*'pres'/'R'/'1000000
'disable fwrite'
i=i+1
endwhile
*
'set fwrite -be -sq -cl c_pblh.dat'
'd pblh'
'disable fwrite'
tiempo=tiempo+1
endwhile
'quit'

