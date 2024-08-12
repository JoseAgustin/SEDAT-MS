#!/bin/csh -f
#           _       _ _ _                                                      _
# ___  __ _| |_ ___| (_) |_ ___      _ __  _ __ ___  _ __   ___  ___   ___ ___| |__
#/ __|/ _` | __/ _ \ | | __/ _ \    | '_ \| '__/ _ \| '_ \ / _ \/ __| / __/ __| '_ \
#\__ \ (_| | ||  __/ | | ||  __/    | |_) | | | (_) | | | | (_) \__ \| (__\__ \ | | |
#|___/\__,_|\__\___|_|_|\__\___|____| .__/|_|  \___/|_| |_|\___/|___(_)___|___/_| |_|
#                             |_____|_|
#   Created by Agustin on 12/04/15.
#   Copyright 2015 UNAM CCA. All rights reserved.
#
# Programa en csh que identifica los archivosl WRF a leer
# procesa para ser leidos por grads  e invoca los scripts
# en grads para extraer la infromacion en la vertical para
# luego invocar los programas que integran en la columna
# total lee_pronos.exe y el que integra hasta a pbl lee_pbl_p.exe
#
set DIR = /Volumes/Pronostico
set LDIR = $PWD
cd $DIR
 set InFiles = (wrfout_d01_2014-06-04_12:00:00 wrfout_d01_2014-07-26_12:00:00 wrfout_d01_2014-08-17_12:00:00)
#
unset DYLD_LIBRARY_PATH
    cd $LDIR
    set Num = 0
    foreach file ( $InFiles )
    set Mes=`echo $file   | awk '{print substr($0,17,2)}'`
    set Dia=`echo $file   | awk '{print substr($0,20,2)}'`
    printf "\nComputations for month %s Day %s \n" $Mes $Dia
        @ Num ++
        /Volumes/Disco2/WRF/ARWpost/util/WRFnc2ctl $DIR/$file -o pronos > temp
        grads -lbc 'satelite_pron1.gs' > temp
        ./lee_pronos.exe >temp
        mv conc.txt ${Mes}${Dia}-16_pron.txt
        ./lee_pbl_p.exe >temp
        mv conc2.txt ${Mes}${Dia}-16_pblh.txt
       grads -lbc 'satelite_pron2.gs' > temp
       ./lee_pronos.exe >temp
        mv conc.txt ${Mes}${Dia}-20_pron.txt
       ./lee_pbl_p.exe >temp
       mv conc2.txt ${Mes}${Dia}-20_pblh.txt
       grads -lbc 'satelite_pron3.gs' > temp
      ./lee_pronos.exe >temp
       mv conc.txt ${Mes}${Dia}-21_pron.txt
      ./lee_pbl_p.exe >temp
      mv conc2.txt ${Mes}${Dia}-21_pblh.txt
     end
     rm d_lon.dat d_lat.dat capas.dat c_so2.dat c_no2.dat c_co.dat temp
     printf "\nDone with Satellite ouput processing for month %s day %s\n" $Mes $Dia