# SEDAT-MS
## Sistema de extracción de datos de modelación para comparación con mediciones de satelite (SEDAT-MS)

El SEDAT-MS consiste en un conjunto de programas en csh, grads y fortran que ejecutan una secuencia de pasos para extraer de las salidas de WRF-chem las concentraciones ambientales de compuestos de interes (NO<sub>2</sub>, SO<sub>2</sub>. CO y O<sub>3</sub>), para horas específicas, estas concentraciones estan a las diferentes alturas que el modelo contiene, luego convierte las concentraciones de ppm a moleculas/m<sup>3</sup> y las integra en la vertical para obtener moleculas/m<sup>2</sup> que es lo que se compara con las mediciones de satelite.

Esto se dan en dos pasos el primero es extraer los valores de concentración integrada de nivel de suelo hasta la última capa del modelo y de nivel de suelo hasta la altura de capa de mezclado (pbl). El segundo paso combina las salidas y genera un archivo por compuesto. Los programas que integran este sistema se describen a continuación:

- `satelite_pronos.csh` esta escrito para csh y es un código que identifica los archivosl __WRF__ a leer procesa para ser leidos por __GrADS__  mediate el programa __WRFnc2ctl__ e invoca los scripts en grads (`satelite_pron1.gs`, `satelite_pron2.gs` y `satelite_pron3.gs``) para extraer la infromacion en la vertical para luego invocar los programas que integran en la columna  total lee_pronos.exe y el que integra hasta a `pbl lee_pbl_p.exe`. 
       
-	`satelite_pron1.gs` guión de instrucciones para GrADS que extrae los datos del WRF en la vertical para las 10:00 horas, genera los archivos: capas.dat d_lat.dat d_lon.dat c_pblh.dat  c_so2.dat c_no2.dat c_co.dat c_o3.dat
       
-	`satelite_pron2.gs` guión de instrucciones para grads que extrae los datos del WRF en la vertical para las 15:00 horas, genera los archivos: capas.dat d_lat.dat d_lon.dat c_pblh.dat  c_so2.dat c_no2.dat c_co.dat c_o3.dat
       
-	`satelite_pron3.gs` guión de instrucciones para grads que extrae los datos del WRF en la vertical para las 16:00 horas, genera los archivos: capas.dat d_lat.dat d_lon.dat c_pblh.dat  c_so2.dat c_no2.dat c_co.dat c_o3.dat
       
-	`lee_capas_pronos.f90` programa en Fortran que leer capas  y hacer la integración en la vertical hasta el ultimo novel del modelo.
       
-	`lee_pbl_pronos.f90` programa en Fortran que leer capas  y hacer la integración en la vertical hasta la pbl.
       
-	`promedios_fcst.f90` programa en Fortran que lee las salidas de la integración en la vertical, y guarda por hora y compuesto los valores obtenidos. Esto se realiza hasta la última capa.
       
-	`promedios_fcst2.f90` programa en Fortran que lee las salidas de la integración en la vertical, y guarda por hora y compuesto los valores obtenidos. Esto se realiza hasta la capa de mezclado.
