#!bin/csh 
#################################################################
#								#
# Make the configuration file to parse parameters for ISCE	#
# stack processor.						#
#								#
#			Lin, Li-Chieh				#
#		Earth and Planetary Sciences			#
#	    University of California, Riverside			#
#	    		 2024.12.24				#
#								#
#################################################################
if ($#argv != 1) then
  echo ""
  echo "Make the configuation file for processing SLC stacks with isce2 stack processor"
  echo "Current version only supports topsStack processor (stackSentinel.py)"
  echo ""
  echo "Example:"
  echo "  csh pop_stack_config.csh sentinel"
  echo "  csh pop_stack_config.csh Sentinel"
  echo ""
  exit 1
endif

set SAT = `echo $1`
if ($SAT != 'sentinel' && $SAT != 'Sentinel') then
  echo ""
  echo "Only supports topsStack processor"
  echo "Please execute this as follows:"
  echo "  csh pop_stack_config.csh sentinel"
  echo "  csh pop_stack_config.csh Sentinel"
  echo "" 
  exit 1
endif


echo "##--------------------- config_stack.cfg ---------------------##" > config_stack.cfg
if ($SAT == 'sentinel' || $SAT == 'Sentinel') then
  echo "######## 0. Adding new stack to existing stack" >> config_stack.cfg
  echo "# Put [yes] to add to existing stack. auto for no" >> config_stack.cfg
  echo "Add_new_stack = auto" >> config_stack.cfg
  echo "# The start date of the new stack" >> config_stack.cfg
  echo "# In the form of yyyymmdd. e.g. 20221030" >> config_stack.cfg
  echo "New_start_date = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "######## 1. Set directories" >> config_stack.cfg
  echo "### Put the directories for SLCs and orbits" >> config_stack.cfg
  echo "# [Directory of SLCs. e.g. /data/SLC]" >> config_stack.cfg
  echo "SLC_dir     = auto"   >> config_stack.cfg
  echo "# [Directory of Orbits. e.g. /data/Orbits]" >> config_stack.cfg
  echo "Orbit_dir   = auto" >> config_stack.cfg
  echo "### Put the directory and name of DEM" >> config_stack.cfg
  echo "# [Path to DEM in use. e.g. /data/DEM/dem.wgs84]" >> config_stack.cfg
  echo "DEM_path    = auto" >> config_stack.cfg
  echo "### Put the directory of auxillary file for Sentinel" >> config_stack.cfg
  echo "# [Directory of the auxillary files. e.g. /data/aux_cal]" >> config_stack.cfg
  echo "AUX_dir     = auto" >> config_stack.cfg
  echo "### Put the directory of where topsStack runfiles will be executed" >> config_stack.cfg
  echo "# [Directory of the working directory. e.g. /data/topsStack]" >> config_stack.cfg
  echo "Work_dir    = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "######## 2. Set ISCE2 topsStack parameters" >> config_stack.cfg
  echo "# See stackSentinel.py -h for detailed explanation. The variables are the same as stackSentinel.py" >> config_stack.cfg
  echo "# auto the default value from ISCE" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Basic options:" >> config_stack.cfg
  echo "POLARIZATION = auto" >> config_stack.cfg
  echo "WORKFLOW     = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Area of interest:" >> config_stack.cfg
  echo "SWATH_NUM    = auto" >> config_stack.cfg
  echo "BBOX         = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Dates of interest:" >> config_stack.cfg
  echo "# yyyymmdd" >> config_stack.cfg
  echo "EXCLUDE_DATES = auto" >> config_stack.cfg
  echo "# yyyymmdd" >> config_stack.cfg
  echo "INCLUDE_DATES = auto" >> config_stack.cfg
  echo "# yyyy-mm-dd" >> config_stack.cfg
  echo "STARTDATE     = auto" >> config_stack.cfg
  echo "# yyyy-mm-dd" >> config_stack.cfg
  echo "STOPDATE      = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Coreistration options:" >> config_stack.cfg
  echo "COREGISTRATION          = auto" >> config_stack.cfg
  echo "REFERENCE_DATE          = auto" >> config_stack.cfg
  echo "SNRTHRESHOLD            = auto" >> config_stack.cfg
  echo "ESDCOHERENCETHRESHOLD   = auto" >> config_stack.cfg
  echo "NUM_OVERLAP_CONNECTIONS = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Interferogram options:" >> config_stack.cfg
  echo "NUM_CONNECTIONS = auto" >> config_stack.cfg
  echo "AZIMUTHLOOKS    = auto" >> config_stack.cfg
  echo "RANGELOOKS      = auto" >> config_stack.cfg
  echo "FILTSTRENGTH    = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Phase unwrapping options" >> config_stack.cfg
  echo "UNW_METHOD = auto" >> config_stack.cfg
  echo "RMFILTER   = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Ionosphere options:" >> config_stack.cfg
  echo "PARAM_ION           = auto" >> config_stack.cfg
  echo "NUM_CONNECTIONS_ION = auto" >> config_stack.cfg
  echo "" >> config_stack.cfg
  echo "### Computing options:" >> config_stack.cfg
  echo "# [Put 'y' for yes; 'n' for no; 'auto' for no]" >> config_stack.cfg
  echo "USE_GPU         = auto" >> config_stack.cfg
  echo "# ['auto' for 1]" >> config_stack.cfg
  echo "NUMPROCESS      = auto" >> config_stack.cfg
  echo "# ['auto' for 1]" >> config_stack.cfg
  echo "NUMPROCESS4TOPO = auto" >> config_stack.cfg
  echo "# ['auto' for nothing]" >> config_stack.cfg
  echo "TEXT_CMD        = auto" >> config_stack.cfg
  echo "# ['auto' for ISCE default]" >> config_stack.cfg
  echo "V               = auto" >> config_stack.cfg
endif





