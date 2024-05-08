#!/home/lichieh/miniforge3/bin/python3.10
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
args = parser.parse_args()

## Pass variables
Input = args.data

print('')
with h5py.File(Input, 'r+') as f:
    keys = np.array(list(f.keys()))
    mBridge_search = fnmatch.filter(keys,'unwrapPhase_mBridge_*')
    times = str(len(mBridge_search))
    DataSet = 'unwrapPhase_mBridge_'+times
    if np.any(keys == 'unwrapPhase_orig'):
        print('***Previous manual bridging detected***')
        if not mBridge_search:
            print('Move unwrapPhase_orig to unwrapPhase')
            del f['unwrapPhase']
            f['unwrapPhase'] = f['unwrapPhase_orig']
            del f['unwrapPhase_orig']
        else:
            print('Move',DataSet,'to unwrapPhase')
            del f['unwrapPhase']
            f['unwrapPhase'] = f[DataSet]
            del f[DataSet]

    else:
        print('Already at the original state')
        print('Exit')

