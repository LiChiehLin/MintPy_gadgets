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

parser = argparse.ArgumentParser(description='Read mintpy generated ifgramStack.h5 to perform bridging (unwrap error correction)')
parser.add_argument('--data','-d',type=str,required=True,help='Full path to ifgramStack.h5 e.g. /data/UAVSAR/mintpy/inputs/ifgramStack.h5')
parser.add_argument('--pair','-p',type=int,nargs='+',required=False,help='Pairs that is going to be bridged. Leave blank will automatically detect all pairs. e.g. 3 10 15 26')
parser.add_argument('--profileStart','-ps',type=int,nargs=2,required=True,help='The start point of the profile. Row Col e.g.: 2500 2500')
parser.add_argument('--profileEnd','-pe',type=int,nargs=2,required=True,help='The end point of the profile. Row Col e.g.: 17500 2500')
parser.add_argument('--searchStep','-ss',type=int,nargs=1,required=True,help='The search step for finding corresponding connect component. Put larger number for longer profiles, smaller number for shorter profiles. e.g. 200')
parser.add_argument('--save',default=False,action='store_true',required=False,help='Plot and save bridged results using mintpy view.py. Leave blank for not plotting')
parser.add_argument('--fix',default=False,action='store_true',required=False,help='Fix (Bridge) it or not. Leave blank for not fixing just for checking which pairs are detected')
parser.add_argument('--overwrite',default=False,action='store_true',required=False,help='Overwrite the current unwrapPhase. Caution! Do this when you already processed at least one time of Profile_Bridging.py otherwise the original unwrapped phase will be overwritten')
args = parser.parse_args()

## Pass variables
Input = args.data
UserPairs = args.pair
Pstart = args.profileStart
Pend = args.profileEnd
Search_step = args.searchStep[0]
Save = args.save
Fix = args.fix
Overwrite = args.overwrite
Datadir = os.path.split(Input)[0]

print('')
print('Data directory:',Datadir)
print('Input data:',Input)
print('Profile starting point:',Pstart)
print('Profile ending point:',Pend)
print('')

if UserPairs:
    print('*** Bridge user-defined pairs',UserPairs)
    print('')
else:
    print('*** Look for every pair')
    print('')

if not Fix:
    print('*** No bridging will be performed. Only search for pairs need to be bridged')
    print('')

if Overwrite:
    print('*** Overwrite the current unwrapPhase')

#### Read data 
## Read 'unwrapPhase' and 'connectComponent'
print('**** Read ',Input,' ****')
ConnComp = readfile.read(Input, datasetName='connectComponent')[0]
UnwrapPha = readfile.read(Input, datasetName='unwrapPhase')[0]
UPhaBridge = np.zeros(UnwrapPha.shape)


#### Find image pairs that need to corrected
## If provided pairs, then only and forcely correct for the pairs
## If pairs not provided, then do an automatic search

# Profile coordinates
dist = np.int64(np.sqrt((Pend[1]-Pstart[1])**2+(Pend[0]-Pstart[0])**2))
Prof_X = np.int64(np.round(np.linspace(Pstart[1],Pend[1],num=dist)))
Prof_Y = np.int64(np.round(np.linspace(Pstart[0],Pend[0],num=dist)))

# Get the size of the data
ImgCount = UnwrapPha.shape[0]


if UserPairs:
    Force = 1
    Pairs = np.array(UserPairs)
else:
    Force = 0
    Pairs = np.arange(0,ImgCount,1)


# Loop through each image pair
FixIO = np.zeros([ImgCount,1])
Ind = np.int64(np.ones([ImgCount,1]))
PhaseStep = np.zeros([ImgCount,2])
for i in range(ImgCount):
    if np.all(i != Pairs):
        FixIO[i] = 0
        continue

    Conn = ConnComp[i,:,:]
    Upha = UnwrapPha[i,:,:]

    # Get the profile
    UphaProf = Upha[Prof_Y,Prof_X]  ## Modify here for delicate profile setting

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

    Ind[i] = np.nanargmin(RMSE).astype(int)
    PhaseStep[i] = m[Ind[i],:]
    # Determine whether this profile needs fixing
    # step < 1 pi:skip; step > 1 pi:fix
    if np.abs(PhaseStep[i,1]) < np.pi and Force == 0:
        FixIO[i] = 0
        print('pair:',i,'No phase step detected')
    elif np.abs(PhaseStep[i,1]) < np.pi and Force == 1:
        FixIO[i] = 1
        print('*************** pair:',i,'Phase step not detected but still correct for it')
    else:
        FixIO[i] = 1
        print('*************** pair:',i,'Phase step detected')


FixPair = np.where(FixIO == 1)[0]
Out = [Pstart,Pend,FixPair]
print('Image pairs:\n',FixPair, 'need to be fixed.')
print('*** Save to',os.path.join(Datadir,'Detected_phase_step.txt'))
print('')
with open(os.path.join(Datadir,'Detected_phase_step.txt'),'w') as f:
    f.write(str(Out))



#### Find corresponding connect component to fix the phase step
for i in range(ImgCount):
    if np.all(i != FixPair):
        print('Skip pair',i)
        UPhaBridge[i,:,:] = UnwrapPha[i,:,:]
        continue

    print('*************** Fixing pair',i,'***************')
    Prof_step_X = Prof_X[Ind[i]]
    Prof_step_Y = Prof_Y[Ind[i]]
    ModelPhase = PhaseStep[i,1]
        
    # Build searching length
    Search_tmp1 = np.sqrt((Pend[1] - Prof_step_X)**2+(Pend[0] - Prof_step_Y)**2)/Search_step
    Search_tmp2 = np.sqrt((Prof_step_X - Pstart[1])**2+(Prof_step_Y - Pstart[0])**2)/Search_step
    if Search_tmp1 >= Search_tmp2:
        Search_length = np.int64(np.floor(Search_tmp2))[0]
    else:
        Search_length = np.int64(np.floor(Search_tmp1))[0]

    # Search for the connect component and unwrapPhase  
    Conn = ConnComp[i,:,:]
    Upha = UnwrapPha[i,:,:]
    UphaDiff = np.zeros([Search_length,1])
    IO = np.zeros([Search_length,3])
    print('Searching for the two corresponding connect components to be fixed.....')
    for j in range(Search_length):
        FrontInd = np.array([Prof_Y[Ind[i] - Search_step*(j+1)], Prof_X[Ind[i] - Search_step*(j+1)]])
        BackInd = np.array([Prof_Y[Ind[i] + Search_step*(j+1)], Prof_X[Ind[i] + Search_step*(j+1)]])

        # Take Connect component as a mask to mask out the according unwrap phase
        ConnFrontInd = Conn[FrontInd[0],FrontInd[1]]  ## Modify here for delicate profile setting
        ConnFront = Conn.copy()
        ConnFront[ConnFront == ConnFrontInd] = 9999
        ConnFront[ConnFront != 9999] = 0
        ConnFront[ConnFront == 9999] = 1
        ConnBackInd = Conn[BackInd[0],BackInd[1]]  ## Modify here for delicate profile setting
        ConnBack = Conn.copy()
        ConnBack[ConnBack == ConnBackInd] = 9999
        ConnBack[ConnBack != 9999] = 0
        ConnBack[ConnBack == 9999] = 1
        
        UphaFront = Upha.copy()
        UphaFront = UphaFront*ConnFront
        UphaBack = Upha.copy()
        UphaBack = UphaBack*ConnBack

        # Calculate unwrap phase difference
        ConnAreaFront = len(ConnFront == 1)
        ConnAreaBack = len(ConnBack == 1)
        UphaFrontAvg = Upha.copy()
        UphaFrontAvg = np.nanmean(UphaFrontAvg[np.repeat(np.linspace(FrontInd[0]-2, FrontInd[0]+2, num=5).astype(int),5), np.tile(np.linspace(FrontInd[1]-2, FrontInd[1]+2, num=5).astype(int).flatten(),5)])
        UphaBackAvg = Upha.copy()
        UphaBackAvg = np.nanmean(UphaBackAvg[np.repeat(np.linspace(BackInd[0]-2, BackInd[0]+2, num=5).astype(int),5), np.tile(np.linspace(BackInd[1]-2, BackInd[1]+2, num=5).astype(int).flatten(),5)])

        UphaDiff[j] = np.abs(UphaFrontAvg - UphaBackAvg)

        # Search pairs that satisfy the threshold
        if UphaDiff[j] <= np.abs(ModelPhase)-0.5*np.pi:
            IO[j,:] = [0,ConnFrontInd[0],ConnBackInd[0]]
        else:
            IO[j,:] = [1,ConnFrontInd[0],ConnBackInd[0]]

    # Determine the pair by looking at the frequency of the pair occurrence
    tmp = np.unique(IO[IO[:,0]==1,1:3],axis=0)
    count = np.zeros([tmp.shape[0],1])
    for k in range(tmp.shape[0]):
        boolean_array = np.array([[IO[:,0] == 1],[IO[:,1] == tmp[k,0]],[IO[:,2] == tmp[k,1]]])
        count[k] = np.sum(boolean_array.all(0))
        
    PairInd = np.argmax(count)
    ConnFrontInd = tmp[PairInd][0]
    ConnBackInd = tmp[PairInd][1]
    print('Pair',i,'Fixing connect components corresponding to',ConnFrontInd,'and',ConnBackInd)
    
    # Add modeled phase step to bridge them together
    ConnFront = Conn.copy()
    ConnFront[ConnFront == ConnFrontInd] = 9999
    ConnFront[ConnFront != 9999] = 0
    ConnFront[ConnFront == 9999] = 1
    ConnBack = Conn.copy()
    ConnBack[ConnBack == ConnBackInd] = 9999
    ConnBack[ConnBack != 9999] = 0
    ConnBack[ConnBack == 9999] = 1

    # Find the phase value nearest to a factor of 2 pi
    AddPhase = np.round(ModelPhase/(2*np.pi)) * (2*np.pi)

    UPhaShift = Upha.copy()
    UphaBack = Upha.copy()
    UphaBack = UphaBack*ConnBack
    UPhaShift = UPhaShift - AddPhase
    UPhaShift = UPhaShift*ConnBack
    UPhaBridge[i,:,:] = Upha - UphaBack + UPhaShift


#### Exit program when no fixing
if not Fix and Save:
    command = 'view.py ' + Input + ' unwrapPhase-' + ' -v' + ' -5' + ' 5' + ' --save ' + '--nodisplay'
    os.system(command)
    exit(1)
elif not Fix and not Save:
    exit(1)


#### Iterate again to see if there is residual phase step
## Guidance for further correction
FixIO = np.zeros([ImgCount,1])
Ind = np.int64(np.zeros([ImgCount,1]))
PhaseStep = np.zeros([ImgCount,2])
print('Check if there is residual phase step among fixed pairs',FixPair)
for i in range(ImgCount):
    if np.all(i != FixPair):
        continue

    Conn = ConnComp[i,:,:]
    Upha = UPhaBridge[i,:,:]

    # Get the profile
    UphaProf = Upha[Prof_Y,Prof_X]  ## Modify here for delicate profile setting

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

    Ind[i] = np.nanargmin(RMSE).astype(int)
    PhaseStep[i] = m[Ind[i],:]
    # Determine whether this profile needs fixing
    # step < 1 pi:skip; step > 1 pi:fix
    if np.abs(PhaseStep[i,1]) < np.pi:
        FixIO[i] = 0
        print('Fixed pair:',i,'No residual phase step detected')
    else:
        FixIO[i] = 1
        print('*************** Fixed pair:',i,'Residual phase step detected')


FixPair = np.where(FixIO == 1)[0]
print('Image pairs:\n',FixPair, 'need to be fixed. Save to Residual_phase_step_pairs.txt')
with open(os.path.join(Datadir,'Residual_phase_step_pairs.txt'),'w') as f:
    f.write(str(FixPair))


#### Check if previous manual bridging exists
with h5py.File(Input, 'r+') as f:
    keys = np.array(list(f.keys()))
    mBridge_search = fnmatch.filter(keys,'unwrapPhase_mBridge_*')
    times = str(len(mBridge_search)+1)
    DataSet = 'unwrapPhase_mBridge_'+times
    if Overwrite:
        print('Overwriting unwrapPhase.....')
        del f['unwrapPhase']
        f.create_dataset('/unwrapPhase',data=UPhaBridge)

    else:    
        if np.any(keys == 'unwrapPhase_orig'):
            print('***Previous manual bridging detected***')
            if not mBridge_search:
                print('Manual bridging done '+times+' time')
                print('Move unwrapPhase to '+DataSet)
                f[DataSet] = f['unwrapPhase']
                del f['unwrapPhase']
                print('Writing to ifgramStack.h5.....')
                f.create_dataset('/unwrapPhase',data=UPhaBridge)

            else:
                print('Manual bridging done '+times+' times')
                print('Move unwrapPhase to '+DataSet)
                f[DataSet] = f['unwrapPhase']
                del f['unwrapPhase']
                print('Writing to ifgramStack.h5.....')
                f.create_dataset('/unwrapPhase',data=UPhaBridge)

        else:
            DataSet = 'unwrapPhase_mBridge_0'
            print('***No previous manual bridging performed before***')
            print('Move unwrapPhase to '+'unwrapPhase_orig')
            f['unwrapPhase_orig'] = f['unwrapPhase']
            del f['unwrapPhase']
            print('Writing to ifgramStack.h5.....')
            f.create_dataset('/unwrapPhase',data=UPhaBridge)

#### Save the corrected unwrap phase using view.py
Outname = os.path.join(Datadir,DataSet)+'.png'
if Save:
    command = 'view.py ' + Input + ' unwrapPhase-' + ' -v' + ' -5' + ' 5' + ' -o ' + Outname + ' --save ' + '--nodisplay'
    os.system(command)



