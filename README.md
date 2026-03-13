# SEDAT-MS — Modeling Data Extraction System for Satellite Comparison

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Language: Fortran](https://img.shields.io/badge/Language-Fortran%2090-orange.svg)]()
[![GrADS](https://img.shields.io/badge/Tool-GrADS-blue.svg)](http://cola.gmu.edu/grads/)
[![WRF-Chem](https://img.shields.io/badge/Model-WRF--Chem-lightblue.svg)](https://ruc.noaa.gov/wrf/wrf-chem/)
[![Published in](https://img.shields.io/badge/Published%20in-ACP%202020-green.svg)](https://doi.org/10.5194/acp-20-15761-2020)

> A pipeline of C-shell, GrADS, and Fortran programs that extracts 3D concentration fields from **WRF-Chem** output files, converts them from ppm to column density (molecules cm⁻²), and integrates them vertically — producing model columns directly comparable to satellite total-column retrievals such as **TROPOMI** (Sentinel-5P).

---

## Table of Contents

- [Scientific Context](#scientific-context)
- [Place in the Analysis Pipeline](#place-in-the-analysis-pipeline)
- [Requirements](#requirements)
- [Repository Structure](#repository-structure)
- [How It Works](#how-it-works)
  - [Step 1 — Vertical profile extraction (GrADS)](#step-1--vertical-profile-extraction-grads)
  - [Step 2 — Unit conversion and vertical integration (Fortran)](#step-2--unit-conversion-and-vertical-integration-fortran)
  - [Step 3 — Aggregation by hour and compound (Fortran)](#step-3--aggregation-by-hour-and-compound-fortran)
- [Column Density Computation](#column-density-computation)
- [Usage](#usage)
- [Input Files](#input-files)
- [Output Files](#output-files)
- [Satellite Comparison](#satellite-comparison)
- [Citation](#citation)
- [References](#references)

---

## Scientific Context

Evaluating air quality model simulations against satellite observations requires converting model output into the same physical quantity that satellites measure: the **vertically integrated column of a trace gas** (expressed in molecules cm⁻²). This is non-trivial because:

- WRF-Chem stores concentrations as **mixing ratios in ppm** on native eta model levels, not as column densities.
- Each model layer has a different pressure, temperature, and thickness that must be accounted for in the integration.
- Satellites like TROPOMI (aboard ESA Sentinel-5P) and OMI (aboard NASA Aura) observe the **total tropospheric column** or the **boundary-layer column** depending on their averaging kernel profile.

SEDAT-MS automates the entire extraction and conversion workflow, generating gridded ASCII column-density files at the satellite overpass times for four key atmospheric pollutants: **CO, NO₂, SO₂, and O₃**.

This tool was used as the post-processing step in a CO source attribution study over central Mexico that combined WRF-Chem passive tracer simulations (using geographic emission masks from [emiss_mask](https://github.com/JoseAgustin/emiss_mask)) with TROPOMI satellite observations to evaluate and improve the national CO emission inventory:

> **Borsdorff, T., García Reynoso, A., Maldonado, G., Mar-Morales, B., Stremme, W., Grutter, M., & Landgraf, J. (2020).** Monitoring CO emissions of the metropolis Mexico City using TROPOMI CO observations. *Atmospheric Chemistry and Physics*, **20**(24), 15761–15774. https://doi.org/10.5194/acp-20-15761-2020

---

## Place in the Analysis Pipeline

SEDAT-MS occupies **step 3** in the following four-stage workflow:

```
┌──────────────────────────────────────────────────────────────────┐
│  1. Emission masking  (emiss_mask)                               │
│     E_CO × geographic masks → per-district tracer variables      │
│     https://github.com/JoseAgustin/emiss_mask                    │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│  2. WRF-Chem passive tracer simulation                           │
│     chem_opt = 106  |  transport-only, no photochemistry         │
│     Output: wrfout_d01_YYYY-MM-DD_HH:MM:SS                       │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│  3. Column extraction  ◄─── THIS REPOSITORY (SEDAT-MS)           │
│     GrADS scripts extract 3D profiles at overpass times          │
│     Fortran programs convert ppm → molecules cm⁻² and integrate  │
│     Output: gridded ASCII column densities per compound          │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│  4. Satellite comparison and source inversion                    │
│     Model columns collocated with TROPOMI S5P_OFFL_L2__CO____    │
│     Linear inversion → per-district emission scaling factors     │
└──────────────────────────────────────────────────────────────────┘
```

---

## Requirements

| Component | Notes |
|---|---|
| GrADS | Version 2.x; used for reading WRF-Chem NetCDF output |
| WRFnc2ctl | Converts WRF-Chem NetCDF files to GrADS-readable descriptor format |
| Fortran compiler | `gfortran` ≥ 6 or Intel `ifort` ≥ 17 |
| C-shell (`csh`) | Required to run the master orchestration script |

> **WRFnc2ctl** is a utility that creates the `.ctl` descriptor file for GrADS from a WRF-Chem NetCDF `wrfout` file. It is available from the [WRF-Chem tools page](https://www2.acom.ucar.edu/wrf-chem/wrf-chem-tools-community) or can be compiled from source within the WRF post-processing utilities.

---

## Repository Structure

```
SEDAT-MS/
├── satelite_pronos.csh      # Master C-shell script — orchestrates the full pipeline
├── satelite_pron1.gs        # GrADS script — extracts vertical profiles at 10:00 local time
├── satelite_pron2.gs        # GrADS script — extracts vertical profiles at 15:00 local time
├── satelite_pron3.gs        # GrADS script — extracts vertical profiles at 16:00 local time
├── lee_capas_pronos.f90     # Fortran — integrates full column (surface to model top)
├── lee_pbl_pronos.f90       # Fortran — integrates boundary-layer column (surface to PBL height)
├── promedios_fcst.f90       # Fortran — aggregates full-column results by hour and compound
├── promedios_fcst2.f90      # Fortran — aggregates PBL-column results by hour and compound
└── README.md                # This file
```

---

## How It Works

The pipeline executes in three sequential steps controlled by `satelite_pronos.csh`.

### Step 1 — Vertical profile extraction (GrADS)

The master script `satelite_pronos.csh` identifies the WRF-Chem `wrfout` files to process, converts them to GrADS format using **WRFnc2ctl**, and then invokes one of three GrADS scripts depending on the target overpass time:

| Script | Local overpass time | Typical satellite |
|---|---|---|
| `satelite_pron1.gs` | 10:00 | TROPOMI morning overpass |
| `satelite_pron2.gs` | 15:00 | OMI afternoon overpass |
| `satelite_pron3.gs` | 16:00 | TROPOMI afternoon overpass |

Each GrADS script extracts the full vertical profile of all state variables needed for the column computation and writes them to binary scratch files:

| File | Contents |
|---|---|
| `capas.dat` | Geopotential height perturbation PH and base-state PHB for each layer |
| `d_lat.dat` | Latitude of each grid cell (degrees N) |
| `d_lon.dat` | Longitude of each grid cell (degrees E) |
| `c_pblh.dat` | Planetary boundary layer height (m) |
| `c_co.dat` | CO mixing ratio vertical profile (ppm) |
| `c_no2.dat` | NO₂ mixing ratio vertical profile (ppm) |
| `c_so2.dat` | SO₂ mixing ratio vertical profile (ppm) |
| `c_o3.dat` | O₃ mixing ratio vertical profile (ppm) |

The pressure perturbation (P) and base-state pressure (PB) and perturbation potential temperature (T) are also extracted for the unit conversion.

### Step 2 — Unit conversion and vertical integration (Fortran)

Two compiled Fortran programs perform the atmospheric column calculation on the scratch files produced in Step 1. Both apply the same unit-conversion equations but integrate over different atmospheric depths:

| Program | Source file | Integration depth |
|---|---|---|
| `lee_pronos.exe` | `lee_capas_pronos.f90` | Surface → top model level (total tropospheric column) |
| `lee_pbl_p.exe` | `lee_pbl_pronos.f90` | Surface → PBLH (boundary-layer column only) |

See [Column Density Computation](#column-density-computation) for the full equation set.

### Step 3 — Aggregation by hour and compound (Fortran)

Two additional Fortran programs read the layer-integrated outputs from Step 2, combine the results across hours and compounds, and write the final gridded column-density files:

| Program | Source file | Output |
|---|---|---|
| `promedios_fcst.exe` | `promedios_fcst.f90` | Full-column density per compound per overpass hour |
| `promedios_fcst2.exe` | `promedios_fcst2.f90` | PBL-column density per compound per overpass hour |

---

## Column Density Computation

The conversion from WRF-Chem ppm mixing ratios to vertical column density (molecules cm⁻²) is computed layer by layer using the full atmospheric state at each grid column. For a single model layer *i*:

| Quantity | Formula | Units | WRF-Chem variables |
|---|---|---|---|
| Layer height | `hᵢ = (PHᵢ + PHBᵢ) / 9.81` | m | `PH`, `PHB` |
| Layer thickness | `Δhᵢ = hᵢ₊₁ − hᵢ` | m | derived |
| Pressure | `Ptᵢ = (Pᵢ + PBᵢ) / 101325` | atm | `P`, `PB` |
| Temperature | `TKᵢ = (Tᵢ + 300) × Ptᵢ^0.2854` | K | `T` |
| Column density per layer | `Xᵢ = xᵢ × Aᵥ × Δhᵢ × Ptᵢ / (TKᵢ × R × 10⁶)` | molecules cm⁻² | species ppm |

where:

| Symbol | Value | Description |
|---|---|---|
| `xᵢ` | — | Species mixing ratio in layer *i* (ppm) |
| `Aᵥ` | 6.023 × 10²³ mol⁻¹ | Avogadro constant |
| `R` | 82.057 cm³ atm mol⁻¹ K⁻¹ | Ideal gas constant |

The total column is the sum over all layers from the surface to the integration ceiling:

```
X_total = Σᵢ Xᵢ   [molecules cm⁻²]
```

The same formula applies identically to CO, NO₂, SO₂, and O₃ — only the input ppm field changes.

> **Note on WRF potential temperature:** WRF stores the perturbation potential temperature `T` such that the full potential temperature is `θ = T + 300 K`. The conversion to actual temperature uses the Poisson relation: `TK = θ × (Pt / 1000)^0.2854` where pressure is in hPa; equivalently, `TK = (T + 300) × Pt^0.2854` when `Pt` is in atm relative to 1 atm.

---

## Usage

### 1. Compile the Fortran programs

```bash
gfortran -O2 -o lee_pronos.exe     lee_capas_pronos.f90
gfortran -O2 -o lee_pbl_p.exe      lee_pbl_pronos.f90
gfortran -O2 -o promedios_fcst.exe promedios_fcst.f90
gfortran -O2 -o promedios_fcst2.exe promedios_fcst2.f90
```

### 2. Configure the master script

Edit `satelite_pronos.csh` to set the paths to your WRF-Chem output files and the working directory:

```csh
# Path to the directory containing wrfout_d01_* files
set wrfout_dir = /path/to/your/wrfout/files

# Working directory where scratch and output files will be written
set work_dir = /path/to/output/directory

# Target overpass time (1 = 10:00, 2 = 15:00, 3 = 16:00 local time)
set overpass = 1
```

### 3. Run the pipeline

```bash
csh satelite_pronos.csh
```

The script will process all `wrfout` files found in `wrfout_dir`, extract profiles at the selected overpass time, perform the column integration, and write the final output files to `work_dir`.

---

## Input Files

| File | Source | Description |
|---|---|---|
| `wrfout_d01_YYYY-MM-DD_HH:MM:SS` | WRF-Chem simulation | Standard WRF output NetCDF file |
| `wrfout_d01_YYYY-MM-DD_HH:MM:SS.ctl` | Generated by WRFnc2ctl | GrADS descriptor file for the wrfout file |

The `wrfout` file must contain the following 3D variables for the column computation: `PH`, `PHB` (geopotential), `P`, `PB` (pressure), `T` (potential temperature perturbation), and the species fields `co`, `no2`, `so2`, `o3` (or equivalent WRF-Chem variable names depending on the chemical mechanism used).

---

## Output Files

SEDAT-MS produces two sets of ASCII gridded files per compound per overpass time:

| File pattern | Integration | Units | Description |
|---|---|---|---|
| `co_col_HH.dat` | Full column | molecules cm⁻² | CO total tropospheric column at hour HH |
| `no2_col_HH.dat` | Full column | molecules cm⁻² | NO₂ total tropospheric column at hour HH |
| `so2_col_HH.dat` | Full column | molecules cm⁻² | SO₂ total tropospheric column at hour HH |
| `o3_col_HH.dat` | Full column | molecules cm⁻² | O₃ total tropospheric column at hour HH |
| `co_pbl_HH.dat` | PBL column | molecules cm⁻² | CO boundary-layer column at hour HH |
| `no2_pbl_HH.dat` | PBL column | molecules cm⁻² | NO₂ boundary-layer column at hour HH |
| `so2_pbl_HH.dat` | PBL column | molecules cm⁻² | SO₂ boundary-layer column at hour HH |
| `o3_pbl_HH.dat` | PBL column | molecules cm⁻² | O₃ boundary-layer column at hour HH |

Each file contains one row per grid cell with columns: `longitude`, `latitude`, `column_density`.

---

## Satellite Comparison

The output files are designed for direct collocation with Level-2 satellite retrievals. For TROPOMI CO comparison, the workflow after SEDAT-MS is:

1. **Read** the SEDAT-MS `co_col_HH.dat` column file on the WRF-Chem grid.
2. **Download** TROPOMI Level-2 CO product files (`S5P_OFFL_L2__CO____`) for the same day from the [Copernicus Open Access Hub](https://scihub.copernicus.eu/) or [S5P Data Hub](https://s5phub.copernicus.eu/).
3. **Collocate** by finding, for each TROPOMI pixel, the nearest WRF-Chem grid cell and matching the observation time to the closest model output time.
4. **Apply TROPOMI averaging kernels** to the modelled vertical profile before integrating, so that both model and satellite represent the same vertical sensitivity. TROPOMI provides pressure-level averaging kernels in the Level-2 product (`column_averaging_kernel`).
5. **Compare and invert**: if using per-district CO tracer fields from [emiss_mask](https://github.com/JoseAgustin/emiss_mask), the collocated per-district columns serve as basis functions in a linear source inversion against the TROPOMI observations.

For OMI NO₂ or SO₂ comparison, use the `no2_col_HH.dat` or `so2_col_HH.dat` files and the corresponding OMI Level-2 product, applying the same collocation and averaging kernel procedure.

---

## Citation

If you use SEDAT-MS in your research, please cite the study in which it was first applied:

> Borsdorff, T., García Reynoso, A., Maldonado, G., Mar-Morales, B., Stremme, W., Grutter, M., & Landgraf, J. (2020). Monitoring CO emissions of the metropolis Mexico City using TROPOMI CO observations. *Atmospheric Chemistry and Physics*, **20**(24), 15761–15774. https://doi.org/10.5194/acp-20-15761-2020

---

## References

- Borsdorff, T., García Reynoso, A., Maldonado, G., Mar-Morales, B., Stremme, W., Grutter, M., & Landgraf, J. (2020). Monitoring CO emissions of the metropolis Mexico City using TROPOMI CO observations. *Atmospheric Chemistry and Physics*, **20**(24), 15761–15774. https://doi.org/10.5194/acp-20-15761-2020

- Grell, G. A., Peckham, S. E., Schmitz, R., McKeen, S. A., Frost, G. J., Skamarock, W. C., & Eder, B. K. (2005). Fully coupled "online" chemistry within the WRF model. *Atmospheric Environment*, **39**, 6957–6975. https://doi.org/10.1016/j.atmosenv.2005.04.027

- Veefkind, J. P., Aben, I., McMullan, K., Förster, H., de Vries, J., Otter, G., Claas, J., Eskes, H. J., de Haan, J. F., Kleipool, Q., van Weele, M., Hasekamp, O., Hoogeveen, R., Landgraf, J., Snel, R., Tol, P., Ingmann, P., Voors, R., Kruizinga, B., Vink, R., Visser, H., & Levelt, P. F. (2012). TROPOMI on the ESA Sentinel-5 Precursor: A GMES mission for global observations of the atmospheric composition for climate, air quality and ozone layer applications. *Remote Sensing of Environment*, **120**, 70–83. https://doi.org/10.1016/j.rse.2011.09.027

- García Reynoso, J. A., Emiss_mask — CO Emission Source Masks for WRF-Chem Tracer Simulations over Central Mexico. GitHub repository. https://github.com/JoseAgustin/emiss_mask

---

*README last updated: March 2026*
