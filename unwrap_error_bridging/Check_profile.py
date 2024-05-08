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

parser = argparse.ArgumentParser(description='Check the profile that samples the unwrapPhase with the given start and end points')
parser.add_argument('--data','-d',type=str,required=True,help='Full path to ifgramStack.h5 e.g. /data/UAVSAR/mintpy/inputs/ifgramStack.h5')
parser.add_argument('--pair','-p',type=int,nargs=1,required=True,help='The pair to check the profile line. Put only 1 pair number')
parser.add_argument('--profileStart','-ps',type=int,nargs=2,required=True,help='The start point of the profile. Row Col e.g.: 2500 2500')
parser.add_argument('--profileEnd','-pe',type=int,nargs=2,required=True,help='The end point of the profile. Row Col e.g.: 17500 2500')
parser.add_argument('--vminmax','-v',type=int,nargs=2,required=False,help='Colorbar of the unwrapped phase. e.g. -v -5 5')
args = parser.parse_args()

## Pass variables
Input = args.data
UserPair = args.pair[0]
Pstart = args.profileStart
Pend = args.profileEnd
Datadir = os.path.split(Input)[0]
v = args.vminmax

if not v:
    v = [-15,15]


print('')
print('Data directory:',Datadir)
print('Input data:',Input)
print('Profile starting point:',Pstart)
print('Profile ending point:',Pend)
print('Looking pair',UserPair)
print('')


## Profile line
dist = np.int64(np.sqrt((Pend[1]-Pstart[1])**2+(Pend[0]-Pstart[0])**2))
Prof_X = np.int64(np.round(np.linspace(Pstart[1],Pend[1],num=dist)))
Prof_Y = np.int64(np.round(np.linspace(Pstart[0],Pend[0],num=dist)))

with h5py.File(Input, 'r') as f:
    Conn = f['connectComponent'][UserPair]
    Upha = f['unwrapPhase'][UserPair]
    
    # Get the profile
    UphaProf = Upha[Prof_Y,Prof_X] 
    
    # Prepare for grid-serach model inversion
    d = UphaProf.copy()
    X = np.arange(0,len(d),1)
    m = np.zeros((len(X),2))
    RMSE = np.zeros((len(X),1))
    for j in range(len(X)):
        # Skip for the first and the last point to avoid singularity
        if j == 0 or j == X[-1]:
            m[j,:] = np.nan
            RMSE[j] = np.nan
        else:
            StepF = np.hstack([np.zeros(j),np.ones(len(X)-j)])
            G = np.vstack([np.ones(len(X)),StepF]).T
            m[j,:] = np.matmul(np.matmul(inv(np.matmul(G.T,G)),G.T),d)
            RMSE[j] = np.sqrt(np.mean((d - (m[j,0] + StepF*m[j,1]))**2))
            
    Ind = np.nanargmin(RMSE).astype(int)
    StepF = np.hstack([np.zeros(Ind),np.ones(len(X)-Ind)])
    PhaseStep = m[Ind,:]

print('*** Show image ***')

plt.figure(figsize=(12,10))
plt.subplot(1,3,1)
plt.imshow(Upha,vmin=v[0],vmax=v[1])
plt.colorbar(pad=0.01)
plt.plot(Prof_X,Prof_Y,'r.',markersize='1')
plt.plot(Prof_X[Ind],Prof_Y[Ind],'ks')
plt.title('unwrapped phase')
plt.subplot(1,3,2)
plt.imshow(Conn)
plt.title('connect component')
plt.plot(Prof_X,Prof_Y,'r.',markersize='1')
plt.plot(Prof_X[Ind],Prof_Y[Ind],'ks')
plt.colorbar(pad=0.01)
plt.subplot(1,3,3)
plt.plot(X,UphaProf,'.',label='unwrapped phase')
plt.plot(X,PhaseStep[0] + StepF*PhaseStep[1],label='Modeled step')
plt.text(Ind,PhaseStep[0],str(round(PhaseStep[1],2)),fontsize=16,weight='bold')
plt.xlabel('X')
plt.ylabel('unwrapped phase')
plt.legend()
plt.tight_layout()
plt.show()
