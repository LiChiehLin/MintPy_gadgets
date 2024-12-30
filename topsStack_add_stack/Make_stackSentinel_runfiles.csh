#!/bin/csh
#################################################################
#                                                               #
# Populate the parameters in configuration files to generate 	#
# the runfiles using stackSentinel.py. This is to add new stacks#
# to existing stacks. Therefore, some lines in the generated 	#
# runfiles will be removed to prevent repeated processing.	#
#                                                               #
#                       Lin, Li-Chieh                           #
#               Earth and Planetary Sciences                    #
#           University of California, Riverside                 #
#                        2024.12.25                             #
#                                                               #
#################################################################
if ($#argv != 1) then
  echo ""
  echo "Populate the parameters in the configuration file to generate runfiles with stackSentinel.py"
  echo "Make sure the stack processor is already in the environment"
  echo ""
  echo "Example:"
  echo "  csh Make_stackSentinel_runfiles.csh config_stack.cfg"
  echo ""
  exit 1
endif


##### Retrieve the parameters
### 0. Adding new stack
set Add_new_stack = `grep -w "Add_new_stack" $1 | awk '{print $3}'`
set New_start_date = `grep -w "New_start_date" $1 | awk '{print $3}'`


### 1. Directories
set SLC_dir = `grep -w "SLC_dir" $1 | awk '{print $3}'`
set Orbit_dir = `grep -w "Orbit_dir" $1 | awk '{print $3}'`
set DEM = ` grep -w "DEM_path" $1 | awk '{print $3}'`
set AUX_dir = `grep -w "AUX_dir" $1 | awk '{print $3}'`
set Work_dir = `grep -w "Work_dir" $1 | awk '{print $3}'`
set command = `echo stackSentinel.py -s $SLC_dir -o $Orbit_dir -a $AUX_dir -w $Work_dir -d $DEM`

### 2. ISCE2 topsStack parameters
# Basic options
set POLARIZATION = `grep -w "POLARIZATION" $1 | awk '{print $3}' | sed 's/auto/vv/g'`
set WORKFLOW = `grep -w "WORKFLOW" $1 | awk '{print $3}' | sed 's/auto/interferogram/g'`
set command = `echo $command -p $POLARIZATION -W $WORKFLOW`

# Area of interest
set SWATH_NUM = `grep -w "SWATH_NUM" $1 | awk '{print $3}' | sed 's/auto/"1 2 3"/g'`
set BBOXcheck = `grep -w "BBOX" $1 | awk '{print $3}'`
set BBOX = `grep -w "BBOX" $1 | awk '{$1=$2=""; print $0}' | cut -c 3-`
if ($BBOXcheck == auto) then
  set command = `echo $command -n $SWATH_NUM`
else
  set command = `echo $command -n $SWATH_NUM -b $BBOX`
endif


# Dates of interest
set EXCLUDE_DATES = `grep -w "EXCLUDE_DATES" $1 | awk '{print $3}'`
set INCLUDE_DATES = `grep -w "INCLUDE_DATES" $1 | awk '{print $3}'`
set STARTDATE = `grep -w "STARTDATE" $1 | awk '{print $3}'`
set STOPDATE = `grep -w "STOPDATE" $1 | awk '{print $3}'`
if ($EXCLUDE_DATES != auto) then
  set command = `echo $command -x $EXCLUDE_DATES`
endif
if ($INCLUDE_DATES != auto) then
  set command = `echo $command -i $INCLUDE_DATES`
endif
if ($STARTDATE != auto) then
  set command = `echo $command --start_date $STARTDATE`
endif
if ($STOPDATE != auto) then
  set command = `echo $command --stop_date $STOPDATE`
endif



# Coregistration
set COREGISTRATION = `grep -w "COREGISTRATION" $1 | awk '{print $3}' | sed 's/auto/NESD/g'`
set REFERENCE_DATE = `grep -w "REFERENCE_DATE" $1 | awk '{print $3}'`
set SNRTHRESHOLD = `grep -w "SNRTHRESHOLD" $1 | awk '{print $3}' | sed 's/auto/10/g'`
set ESDCOHERENCETHRESHOLD = `grep -w "ESDCOHERENCETHRESHOLD" $1 | awk '{print $3}' | sed 's/auto/0.85/g'`
set NUM_OVERLAP_CONNECTIONS = `grep -w "NUM_OVERLAP_CONNECTIONS" $1 | awk '{print $3}' | sed 's/auto/3/g'`
if ($REFERENCE_DATE != auto) then
  set command = `echo $command -C $COREGISTRATION -m $REFERENCE_DATE --snr_misreg_threshold $SNRTHRESHOLD -e $ESDCOHERENCETHRESHOLD -O $NUM_OVERLAP_CONNECTIONS`
else
  set command = `echo $command -C $COREGISTRATION --snr_misreg_threshold $SNRTHRESHOLD -e $ESDCOHERENCETHRESHOLD -O $NUM_OVERLAP_CONNECTIONS`
endif

# Interferogram options
set NUM_CONNECTIONS = `grep -w "NUM_CONNECTIONS" $1 | awk '{print $3}' | sed 's/auto/1/g'`
set AZIMUTHLOOKS = `grep -w "AZIMUTHLOOKS" $1 | awk '{print $3}' | sed 's/auto/3/g'`
set RANGELOOKS = `grep -w "RANGELOOKS" $1 | awk '{print $3}' | sed 's/auto/9/g'`
set FILTSTRENGTH = `grep -w "FILTSTRENGTH" $1 | awk '{print $3}' | sed 's/auto/0.5/g'`
set command = `echo $command -c $NUM_CONNECTIONS -z $AZIMUTHLOOKS -r $RANGELOOKS -f $FILTSTRENGTH`

# Phase unwrapping
set UNW_METHOD = `grep -w "UNW_METHOD" $1 | awk '{print $3}' | sed 's/auto/snaphu/g'`
set RMFILTER = `grep -w "RMFILTER" $1 | awk '{print $3}'`
if ($RMFILTER != auto) then
  set command = `echo $command -u $UNW_METHOD --rmFilter`
else
  set command = `echo $command -u $UNW_METHOD`
endif


# Ionosphere options
set PARAM_ION = `grep -w "PARAM_ION" $1 | awk '{print $3}'`
set NUM_CONNECTIONS_ION = `grep -w "NUM_CONNECTIONS_ION" $1 | awk '{print $3}' | sed 's/auto/3/g'`
if ($PARAM_ION != auto) then
  set command = `echo $command --param_ion $PARAM_ION --num_connections_ion $NUM_CONNECTIONS_ION`
endif

# Computing options
set USE_GPU = `grep -w "USE_GPU" $1 | awk '{print $3}'`
set NUMPROCESS = `grep -w "NUMPROCESS" $1 | awk '{print $3}' | sed 's/auto/1/g'`
set NUMPROCESS4TOPO = `grep -w "NUMPROCESS4TOPO" $1 | awk '{print $3}' | sed 's/auto/1/g'`
set TEXT_CMD = `grep -w "TEXT_CMD" $1 | awk '{print $3}'`
set V = `grep -w "V" $1 | awk '{print $3}'`
set command = `echo $command --num_proc $NUMPROCESS --num_proc4topo $NUMPROCESS4TOPO`

if ($USE_GPU != auto) then 
  set command = `echo $command --useGPU`
endif
if ($TEXT_CMD != auto) then
  set command = `echo $command -t $TEXT_CMD`
endif
if ($V != auto) then
  set command = `echo $command -V $V`
endif

################################
echo "*** Running stackSentinel.py with the following parameters:"
echo "# Add_new_stack:   $Add_new_stack"
echo "# New_start_date:  $New_start_date"
echo ""
echo "# SLC_dir:      $SLC_dir"
echo "# Orbit_dir:    $Orbit_dir"
echo "# DEM:          $DEM"
echo "# AUX_dir:      $AUX_dir"
echo "# Work_dir:     $Work_dir"
echo ""
echo "# Polarization: $POLARIZATION"
echo "# Workflow:     $WORKFLOW"
echo ""
echo "# Swaths to process: $SWATH_NUM"
echo "# Bounding box:      $BBOX"
echo ""
echo "# Excluded dates:    $EXCLUDE_DATES"
echo "# Included dates:    $INCLUDE_DATES"
echo "# Start date:        $STARTDATE"
echo "# Stop date:         $STOPDATE"
echo ""
echo "# Coregistration:           $COREGISTRATION"
echo "# Reference date:           $REFERENCE_DATE"
echo "# SNR threshold:            $SNRTHRESHOLD"
echo "# ESD coherence threshold   $ESDCOHERENCETHRESHOLD"
echo "# Number of overlap:        $NUM_OVERLAP_CONNECTIONS"
echo ""
echo "# Number of connections:  $NUM_CONNECTIONS"
echo "# Multilook azimuth:      $AZIMUTHLOOKS"
echo "# Multilook range:        $RANGELOOKS"
echo "# Filter strength:        $FILTSTRENGTH"
echo ""
echo "# Unwrapping method:      $UNW_METHOD"
echo "# rmFilter:               $RMFILTER"
echo ""
echo "# Ionosphere file:            $PARAM_ION"
echo "# Number of connection, ION:  $NUM_CONNECTIONS_ION"
echo ""
echo "# Use GPU: 		      $USE_GPU"
echo "# Number of processor:        $NUMPROCESS"
echo "# Number of processor, topo:  $NUMPROCESS4TOPO"
echo "# Text:			      $TEXT_CMD"
echo "# V:			      $V"

echo ""

### Run stackSentinel.py or not
echo "Execute stackSentinel.py or not..."
echo "[Y/y] to continue. [N/n] to exit"
set req = $<
if ($req == 'Y' || $req == 'y') then
  echo "*** Create command_stackSentinel.txt to `pwd`"
  echo $command > command_stackSentinel.txt
  csh command_stackSentinel.txt

  ### Reomve the existing pairs in run_files/
  if ($Add_new_stack == yes) then
    echo ""
    echo "*** Removing pairs that are already processed in previous runs"
    echo "* Assumes everything before start date: $New_start_date is processed"
    echo "* Only modifies run_13 to run_16"
    echo "**************************************************"
    # Go to ${Work_dir}/run_files, go through run_13 to run_16 to remove repeated pairs
    cd ${Work_dir}/run_files
    if (! -d modified_runfiles) then
      mkdir modified_runfiles
    endif
  
    foreach file (`ls run_*`)
      set num = `echo $file | awk -F_ '{print $2}'`
      if ($num == 13 || $num == 14 || $num == 15 || $num == 16) then
        echo "* Runfile: $file" 
        # Find the starting row of the newly added stack
        cat ${file} | rev | cut -c 10-17 | rev > date1
        cat ${file} | rev | cut -c 1-8 | rev > date2
        paste date1 date2 > date12
        set PrintNumAfter = `cat date12 | awk '{if ($1==New_start_date || $2==New_start_date) print NR}' New_start_date=$New_start_date | head -1`
  
        # Print them into a new file
        cat ${file} | awk 'NR>=PrintNumAfter {print $0}' PrintNumAfter=$PrintNumAfter
        cat ${file} | awk 'NR>=PrintNumAfter {print $0}' PrintNumAfter=$PrintNumAfter > ${file}_modified
        mv ${file}_modified modified_runfiles/
        echo ""
      else
        cp $file modified_runfiles/${file}_modified
      endif
    end
    echo "* Runfiles store in ${Work_dir}/run_files/modified_runfiles"
    # Clean up
    rm date1 date2 date12
  
  else if ($Add_new_stack == auto || $Add_new_stack == no) then
    echo ""
    echo "No adding new stack. Assumes this is the first run."
    echo "Keep all runfiles as it is."
    echo ""
  endif

else if ($req == 'N' || $req == 'n') then
  echo "Exit! Command line for stackSentinel.py stored in command_stackSentinel.txt"
  echo $command > command_stackSentinel.txt
  exit 1
else
  echo "Put either [Y/y] or [N/n]"
  exit 1
endif





