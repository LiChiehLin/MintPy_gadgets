# Workflow for ISCE(topsStack)-MintPy 
This is designed for both **routine processing of topsStack-MintPy** and **subsequent updates of InSAR timeseries** when newer data is available  
The purpose of this is to make easier communication between `ISCE` and `MintPy`, at least for me.  
  
  
The following example assumes the directory arrangement as such:  
```bash
├── topsStack/
├── SLC/
│   ├── S1A_IW_SLC__1SDV_20240808T215230_20240808T215300_055127_06B7C1_EB14.zip
│   ├── S1A_IW_SLC__1SDV_20240820T215230_20240820T215300_055302_06BE24_8516.zip
│   ├── S1A_IW_SLC__1SDV_20240901T215230_20240901T215300_055477_06C49D_8A60.zip
│   ├── S1A_IW_SLC__1SDV_20240913T215231_20240913T215300_055652_06CB88_2F20.zip
│   ├── ...
├── Orbit/
│   ├── S1A_OPER_AUX_POEORB_OPOD_20240828T070608_V20240807T225942_20240809T005942.EOF
│   ├── S1A_OPER_AUX_POEORB_OPOD_20240909T070622_V20240819T225942_20240821T005942.EOF
│   ├── S1A_OPER_AUX_POEORB_OPOD_20240921T070612_V20240831T225942_20240902T005942.EOF
│   ├── S1A_OPER_AUX_RESORB_OPOD_20240913T233024_V20240913T193115_20240913T224845.EOF
│   ├── ...
├── DEM/
│   ├── demLat_N22_N26_Lon_E120_E123.dem.wgs84
│   ├── demLat_N22_N26_Lon_E120_E123.dem.wgs84.vrt
│   ├── demLat_N22_N26_Lon_E120_E123.dem.wgs84.xml
├── AUX/
│   ├── S1A_AUX_CAL_V20140908T000000_G20190626T100201.SAFE.zip
│   ├── ...
├── Add_new_stack_MintPy.csh
├── Make_stackSentinel_runfiles.csh
├── pop_stack_config.csh
└── config_stack.cfg
```

### Check the usage of each CShell
Simply execute the CShell code without entering any input. You will see a brief example of it
```console
csh Add_new_stack_MintPy.csh
csh Make_stackSentinel_runfiles.csh
csh pop_stack_config.csh

```

---
## 1. Prepare configuration file
2 ways to do this:
  - Download `config_stack.cfg` from this repository to your current working direcotry
  - Execute `pop_stack_config.csh` to generate a template configuration file
```console
csh pop_stack_config.csh sentinel
# or
csh pop_stack_config.csh Sentinel
```

There are 3 sections in the configuration file:  
### Section 0: Is this stack processing adding to an existing stack
Leave the two parameter as `auto` if this is not for sequential updating timeseries;   
If it is, then put yes and the start date as shown below:  
```cfg
Add_new_stack = yes
New_start_date = 20240913
```

### Section 1: Directories
Put the directories of `SLCs`, `Orbits`, the `path/dem`, `auxiliary file`, and the `working directory` to the corresponding variables
```cfg
SLC_dir   = SLC
Orbit_dir = Orbit
DEM_path  = DEM/demLat_N22_N26_Lon_E120_E123.dem.wgs84
AUX_dir   = AUX
Work_dir  = topsStack
```

### Section 2: ISCE topsStack parameters
These are the parameters `topsStack` processor requires. Leave as auto to use the default values  
The parameter names resemble the way ISCE names them. Users should easily recognize it.  
```cfg
### Basic options:
POLARIZATION = auto
WORKFLOW     = auto

### Area of interest:
SWATH_NUM    = auto
BBOX         = auto

### Dates of interest:
# yyyymmdd
EXCLUDE_DATES = auto
# yyyymmdd
INCLUDE_DATES = auto
# yyyy-mm-dd
STARTDATE     = auto
# yyyy-mm-dd
STOPDATE      = auto

### Coregistration options:
COREGISTRATION          = auto
REFERENCE_DATE          = auto
SNRTHRESHOLD            = auto
ESDCOHERENCETHRESHOLD   = auto
NUM_OVERLAP_CONNECTIONS = auto

### Interferogram options:
NUM_CONNECTIONS = auto
AZIMUTHLOOKS    = auto
RANGELOOKS      = auto
FILTSTRENGTH    = auto

### Phase unwrapping options
UNW_METHOD = auto
RMFILTER   = auto

### Ionosphere options:
PARAM_ION           = auto
NUM_CONNECTIONS_ION = auto

### Computing options:
USE_GPU         = auto
NUMPROCESS      = auto
NUMPROCESS4TOPO = auto
TEXT_CMD        = auto
V               = auto
```

## 2. Run Make_stackSentinel_runfiles.csh
To run this Cshell. run:
```shell
csh Make_stackSentinel_runfiles.csh config_stack.cfg
# You will be asked to whether run stackSentinel.py now or not.
# [Y/y] to execute; [N/n] not to
```
If you put `Add_new_stack = yes` and a designated start date `New_start_date = 20240913` at section 0,  
then you will notice, in `topsStack/runfiles`, there will be a new folder named `modified_runfiles`.  
  
All run files will have the suffix `modified`. The pairs before `New_start_date` in run file 13 to 16 will be removed.


## 3.1. Execute the runfiles
Execute the run files as usual with ISCE.  
If `Add_new_stack = auto` then everything now should be done.  
If `Add_new_stack = yes` then see below:


## 3.2. Arrange results with Add_new_stack_MintPy.csh
Make symbolic links to either a `new shared folder` or the `original timeseries folder`  
This routine also runs `prep_isce.py` to the added stack for MintPy.  

Assume the original timeseries folder is `topsStack`, the added stack is `topsStack2`
```bash
├── topsStack/
│   ├── baselines/
│   ├── reference/
│   ├── merged/
│   │   ├── geom_reference/
│   │   └── interferograms/
├── topsStack2/
│   ├── baselines/
│   ├── reference/
│   ├── merged/
│   │   ├── geom_reference/
│   │   └── interferograms/
├── SLC/
│   ├── ...
├── Orbit/
│   ├── ...
├── DEM/
│   ├── ...
├── AUX/
│   ├── ...
├── Add_new_stack_MintPy.csh
├── Make_stackSentinel_runfiles.csh
├── pop_stack_config.csh
└── config_stack.cfg
```
Run in one of the two following ways:
```shell
# If you want them to be in a new shared folder, then you need to give the name of the shared folder.
# The code will create the shared folder with the name you put
csh Add_new_stack_MintPy.csh topsStack/ topsStack2/ NEW_SHARED/

# If you want the added stack to be included in the original stack, simply:
# This will create necessary symbolic links in the corresponding folders in the original stack
csh Add_new_stack_MintPy.csh topsStack/ topsStack2/

```
After that, run `MintPy` as usual and should be done.  
Mind the change in reference_date  

Good luck!








