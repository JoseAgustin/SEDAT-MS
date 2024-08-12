# SEDAT-MS
## Modeling Data Extraction System for comparison with satellite measurements (SEDAT-MS)

The SEDAT-MS consists of a set of programs in csh, GrADS, and Fortran that execute a sequence of steps to extract from the __WRF-chem__ outputs the environmental concentrations of compounds of interest (NO<sub>2</sub>, SO <sub>2</sub>. CO and O<sub>3</sub>), for specific times, these concentrations are at the different heights that the model contains, then convert the concentrations from ppm to molecules/m<sup >3</sup> and integrates them vertically to obtain molecules/m<sup>2</sup> which is what is compared with satellite measurements.

This is done in two steps: the first is to extract the integrated concentration values ​​from the ground level to the last layer of the model and from the ground level to the mixing layer height (pbl). The second step combines the outputs and generates one file per compound. The programs that make up this system are described below:

- `satelite_pronos.csh` is written for csh and is a code that identifies the __WRF__ files to be read, processes them to be read by __GrADS__ through the __WRFnc2ctl__ program and invokes the scripts in grads (`satelite_pron1.gs`, `satelite_pron2.gs` and `satellite_pron3.gs`) to extract the information in the vertical and then invoke the programs that integrate lee_pronos.exe in the total column and the one that integrates up to the mixing layer (PBL) `lee_pbl_p.exe`.

- `satellite_pron1.gs` script for GrADS that extracts the WRF data in the vertical for 10:00 hours, generates the files: capa.dat d_lat.dat d_lon.dat c_pblh.dat c_so2.dat c_no2.dat c_co .dat c_o3.dat

- `satellite_pron2.gs` script for grads that extracts the WRF data in the vertical for 15:00 hours, generates the files: capa.dat d_lat.dat d_lon.dat c_pblh.dat c_so2.dat c_no2.dat c_co .dat c_o3.dat

- `satellite_pron3.gs` script for grads that extracts the WRF data in the vertical for 16:00 hours, generates the files: capa.dat d_lat.dat d_lon.dat c_pblh.dat c_so2.dat c_no2.dat c_co .dat c_o3.dat

- `lee_capas_pronos.f90` Fortran program that reads layers and performs vertical integration up to the last level of the model.

- `lee_pbl_pronos.f90` Fortran program that reads layers and does the vertical integration up to the pbl.

- `promedios_fcst.f90` Fortran program that reads the outputs of the vertical integration, and saves the obtained values ​​by hour and compound. This is done until the last layer.

- `promedios_fcst2.f90` Fortran program that reads the outputs of the vertical integration, and saves the obtained values ​​by hour and compound. This is done up to the mixing layer.

## Method

Computes the molecules per square meter by:

1) Computing the height of each layer using the following equation  h<sub>i</sub>=(PH<sub>i</sub>+PHB<sub>i</sub>)/9.81
2) The Layer tickness computation layer=h<sub>i+1</sub>-h<sub>i</sub> [m]
3) Pressure Pt=(P<sub>i</sub>+PB<sub>i</sub>)/101325 [from Pa to atm]
5) Temperature in Kelvin TK<sub>i</sub>= (T<sub>i</sub>+300)*ff   where ff=Pt<sup >0.2854</sup>
6) concentration of SO<sub>2</sub> = so2<sub>i</sub> Av/TK<sub>i</sub>*Pt<sub>i</sub>/R/1e6 [molec/cm<sup>2</sup>] where Av= 6.023E23 molecules/mol, R= 82.057 and so2<sub>i</sub>- is the WRF-chem output for SO<sub>2</sub> in ppm.
7) Same computation for CO, NO<sub>2</sub> and O<sub>3</sub>

## Sistema de extracción de datos de modelación para comparación con mediciones de satelite (SEDAT-MS)

El SEDAT-MS consiste en un conjunto de programas en csh, grads y fortran que ejecutan una secuencia de pasos para extraer de las salidas de WRF-chem las concentraciones ambientales de compuestos de interes (NO<sub>2</sub>, SO<sub>2</sub>. CO y O<sub>3</sub>), para horas específicas, estas concentraciones estan a las diferentes alturas que el modelo contiene, luego convierte las concentraciones de ppm a moleculas/m<sup>3</sup> y las integra en la vertical para obtener moleculas/m<sup>2</sup> que es lo que se compara con las mediciones de satelite.

Esto se dan en dos pasos el primero es extraer los valores de concentración integrada de nivel de suelo hasta la última capa del modelo y de nivel de suelo hasta la altura de capa de mezclado (pbl). El segundo paso combina las salidas y genera un archivo por compuesto. Los programas que integran este sistema se describen a continuación:

- `satelite_pronos.csh` esta escrito para csh y es un código que identifica los archivosl __WRF__ a leer procesa para ser leidos por __GrADS__  mediate el programa __WRFnc2ctl__ e invoca los scripts en grads (`satelite_pron1.gs`, `satelite_pron2.gs` y `satelite_pron3.gs`) para extraer la informaicion en la vertical para luego invocar los programas que integran en la columna  total lee_pronos.exe y el que integra hasta a `pbl lee_pbl_p.exe`. 
       
-	`satelite_pron1.gs` guión de instrucciones para GrADS que extrae los datos del WRF en la vertical para las 10:00 horas, genera los archivos: capas.dat d_lat.dat d_lon.dat c_pblh.dat  c_so2.dat c_no2.dat c_co.dat c_o3.dat
       
-	`satelite_pron2.gs` guión de instrucciones para grads que extrae los datos del WRF en la vertical para las 15:00 horas, genera los archivos: capas.dat d_lat.dat d_lon.dat c_pblh.dat  c_so2.dat c_no2.dat c_co.dat c_o3.dat
       
-	`satelite_pron3.gs` guión de instrucciones para grads que extrae los datos del WRF en la vertical para las 16:00 horas, genera los archivos: capas.dat d_lat.dat d_lon.dat c_pblh.dat  c_so2.dat c_no2.dat c_co.dat c_o3.dat
       
-	`lee_capas_pronos.f90` programa en Fortran que leer capas  y hacer la integración en la vertical hasta el ultimo novel del modelo.
       
-	`lee_pbl_pronos.f90` programa en Fortran que leer capas  y hacer la integración en la vertical hasta la pbl.
       
-	`promedios_fcst.f90` programa en Fortran que lee las salidas de la integración en la vertical, y guarda por hora y compuesto los valores obtenidos. Esto se realiza hasta la última capa.
       
-	`promedios_fcst2.f90` programa en Fortran que lee las salidas de la integración en la vertical, y guarda por hora y compuesto los valores obtenidos. Esto se realiza hasta la capa de mezclado.

## Método

Calcula las moléculas por metro cuadrado mediante:

1) Calcular la altura de cada capa usando la siguiente ecuación h<sub>i</sub>=(PH<sub>i</sub>+PHB<sub>i</sub>)/9.81
2) Cálculo del espesor de la capa Layer=h<sub>i+1</sub>-h<sub>i</sub> [m]
3) Presión Pt=(P<sub>i</sub>+PB<sub>i</sub>)/101325 [de Pa a atm]
5) Temperatura en Kelvin TK<sub>i</sub>= (T<sub>i</sub>+300)*ff donde ff=Pt<sup >0.2854</sup>
6) concentración de SO<sub>2</sub> = so2<sub>i</sub> Av/TK<sub>i</sub>*Pt<sub>i</sub>/R/1e6 [molec /cm<sup>2</sup>] donde Av= 6.023E23 moléculas/mol, R= 82.057 y so2<sub>i</sub>- es la salida química de WRF para SO<sub>2</sub> en ppm.
7) Mismo cálculo para CO, NO<sub>2</sub> y O<sub>3</sub>
