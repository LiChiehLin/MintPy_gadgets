#!/bin/csh
#################################################################
#                                                               #
# Add a new SLC stack to an existing SLC stack.			#
# This is a routine for ISCE-MintPy workflow with topsStack 	#
#                                                               #
#                       Lin, Li-Chieh                           #
#               Earth and Planetary Sciences                    #
#           University of California, Riverside                 #
#                        2024.12.29                             #
#                                                               #
#################################################################
if ($#argv != 2 && $#argv != 3) then
  echo ""
  echo "# Make symbolic links of added stack to the directory where the original stack was run"
  echo "# Also, run prep_isce.py for newly added pairs to facilitate MintPy"
  echo ""
  echo "Note that:"
  echo "  For original and added stack directories, just put the folder name"
  echo "  Please place everything in the current folder where this is executed, or refer to the folder arrangement at:"
  echo ""
  echo ""
  echo "Input 1: Folder name of original stack"
  echo "Input 2: Folder name of added stack"
  echo "Input 3: The name of the new directory (Leave blank to put symbolic links to the original stack directory)"
  echo ""
  echo "Example 1: Make links to the original stack directory"
  echo "  csh Add_new_stack_MintPy.csh orig_stack_dir added_stack_dir"
  echo ""
  echo "Example 2: Create a new directory and make symbolic links to it"
  echo "  csh Add_new_stack_MintPy.csh orig_stack_dir added_stack_dir combined_stack_dir"
  echo ""
  exit 1
endif

# Retrieve variables
set PWD = `pwd`
if ($#argv == 2) then
  set Orig_stack_dir = `echo ${PWD}/$1`
  set Added_stack_dir = `echo ${PWD}/$2`
  set flag = 0
else 
  set Orig_stack_dir = `echo ${PWD}/$1`
  set Added_stack_dir = `echo ${PWD}/$2`
  set New_stack_dir = `echo ${PWD}/$3`
  if (! -d ${New_stack_dir} ) then
    mkdir ${New_stack_dir}
  endif
  set flag = 1
endif


########################################## Start #########################################3
cd ${Added_stack_dir}
echo "*** Running prep_isce.py at ${Added_stack_dir}"
set IW = `ls reference/IW*.xml | rev | awk -F/ '{print $1}' | rev | head -1`
prep_isce.py -f "merged/interferograms/*/filt_*.unw" -m reference/$IW -b baselines/ -g merged/geom_reference

cd $PWD
if ($flag == 0) then
  echo ""
  echo "*** Linking ${Added_stack_dir}/baselines/*"
  ln -s ${Added_stack_dir}/baselines/* ${Orig_stack_dir}/baselines
  
  echo "*** Linking ${Added_stack_dir}/merged/interferograms/*"
  ln -s ${Added_stack_dir}/merged/interferograms/* ${Orig_stack_dir}/merged/interferograms

else if ($flag == 1) then
  echo ""
  #### Make all corresponding folders 
  if (! -d ${New_stack_dir}/reference) then
    mkdir ${New_stack_dir}/reference
  endif
  if (! -d ${New_stack_dir}/baselines) then
    mkdir ${New_stack_dir}/baselines
  endif
  if (! -d ${New_stack_dir}/merged) then
    mkdir ${New_stack_dir}/merged
  endif
  if (! -d ${New_stack_dir}/merged/interferograms) then
    mkdir ${New_stack_dir}/merged/interferograms
  endif
  if (! -d ${New_stack_dir}/merged/geom_reference) then
   mkdir ${New_stack_dir}/merged/geom_reference
  endif

  echo "*** Linking ${Orig_stack_dir}/reference/IW*.xml"
  ln -s ${Orig_stack_dir}/reference/IW*.xml ${New_stack_dir}/reference
  
  echo "*** Linking ${Orig_stack_dir}/baselines/"
  ln -s ${Orig_stack_dir}/baselines/* ${New_stack_dir}/baselines
  
  echo "*** Linking ${Orig_stack_dir}/merged/interferograms/*"
  ln -s ${Orig_stack_dir}/merged/interferograms/* ${New_stack_dir}/merged/interferograms
  
  echo "*** Linking ${Orig_stack_dir}/merged/geom_reference/*"
  ln -s ${Orig_stack_dir}/merged/geom_reference/* ${New_stack_dir}/merged/geom_reference
  
  echo ""
  
  #### Added stack
  echo "*** Linking ${Added_stack_dir}/baselines/*"
  ln -s ${Added_stack_dir}/baselines/* ${New_stack_dir}/baselines
  
  echo "*** Linking ${Added_stack_dir}/merged/interferograms/*"
  ln -s ${Added_stack_dir}/merged/interferograms/* ${New_stack_dir}/merged/interferograms

endif






