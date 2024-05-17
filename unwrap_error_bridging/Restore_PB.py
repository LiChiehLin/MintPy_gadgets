# ------------------------------------------ #
# Department of Earth and Planetary Sciences #
#                                            #
#   University of California, Riverside      #
#                                            #
#               Li-Chieh Lin                 #
#                2024.05.09                  #
#                                            #
# Updates: 2024.05.17                        #
# Allow desgnated pair restoration           #
# given by argument -p                       #
# ------------------------------------------ #

import os
import numpy as np
import h5py
import argparse
import fnmatch
from numpy.linalg import inv
from matplotlib import pyplot as plt
from mintpy.objects import timeseries, sensor
from mintpy.utils import readfile, writefile
from mintpy.defaults.plot import *
from mintpy import view

parser = argparse.ArgumentParser(description='Restore the previous manually bridging result, remove the current one. Use when the current bridging result is not satisfactory')
parser.add_argument('--data','-d',type=str,required=True,help='Full path to ifgramStack.h5 e.g. /data/UAVSAR/mintpy/inputs/ifgramStack.h5')
parser.add_argument('--pair','-p',type=int,nargs='+',required=False,help='Desired pairs that need to be restored. Leave blank will restore all pairs. e.g. 3 10 15 26')
args = parser.parse_args()

## Pass variables
Input = args.data
Pair = args.pair

if Pair: 
    print('*** Restore pairs,',Pair)
    print('')

else:
    print('*** No input pairs. Restore all pairs')
    print('')

with h5py.File(Input, 'r+') as f:
    keys = np.array(list(f.keys()))
    mBridge_search = fnmatch.filter(keys,'unwrapPhase_mBridge_*')
    times = str(len(mBridge_search))
    DataSet = 'unwrapPhase_mBridge_'+times
    ImgCount = f['unwrapPhase'].shape[0]
    if np.any(keys == 'unwrapPhase_orig'):
        print('***Previous manual bridging detected***')
        if not mBridge_search:
            if Pair:
                print('Restoring pairs:',Pair,'from unwrapPhase_orig')
                ResMat = np.zeros(f['unwrapPhase'].shape)
                for i in range(ImgCount):
                    if np.any(i in Pair):
                        print(i,'Restore it')
                        ResMat[i,:,:] = f['unwrapPhase_orig'][i,:,:]
                    else:
                        print(i,'Remains unchanged')
                        ResMat[i,:,:] = f['unwrapPhase'][i,:,:]

                print('*** Creating .h5 dataset /unwrapPhase')
                del f['unwrapPhase']
                f.create_dataset('/unwrapPhase',data=ResMat)

            else:
                print('Move unwrapPhase_orig to unwrapPhase')
                del f['unwrapPhase']
                f['unwrapPhase'] = f['unwrapPhase_orig']
                del f['unwrapPhase_orig']

        else:
            if Pair:
                print('Restoring pairs:',Pair,'from',DataSet)
                ResMat = np.zeros(f['unwrapPhase'].shape)
                for i in range(ImgCount):
                    if np.any(i in Pair):
                        print(i,'Restore it')
                        ResMat[i,:,:] = f[DataSet][i,:,:]
                    else:
                        print(i,'Remains unchanged')
                        ResMat[i,:,:] = f['unwrapPhase'][i,:,:]

                print('*** Creating .h5 dataset /unwrapPhase')
                del f['unwrapPhase']
                f.create_dataset('/unwrapPhase',data=ResMat)

            else:    
                print('Move',DataSet,'to unwrapPhase')
                del f['unwrapPhase']
                f['unwrapPhase'] = f[DataSet]
                del f[DataSet]

    else:
        print('Already at the original state')
        print('Exit')


