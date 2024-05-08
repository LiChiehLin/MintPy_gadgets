# Correct unwrap erorr with bridging method

* Main bridging program: `Profile_Bridging.py`
* Restore the previous profile bridging results: `Restore_PB.py`
* Check the profile and visualize: `Check_profile.py`

Each description of the code can be accessed via in terminal window:
```python
python Profile_Bridging.py -h
```

---
### Profile_Bridging.py
Perform the profile bridging technique to .h5 dataset `unwrapPhase`  
#### Note that the unwrapped phase in the connect component at the end of the profile will be shifted to match the unwrapped phase at the front profile. So if you got a reversed fixing, try run `Restore_PB.py` to restore the previous results and reverse your profile
* Required:
  * -d: Data: The absolute path of `ifgramStack.h5`
  * -ps: ProfileStart: Starting point of the profile.
  * -pe: ProfileEnd: Ending point of the profile.
  * -ss: SearchStep: Searching step along the profile. 
* Optional:
  * -p: Pairs: Indices of pairs to bridge.
  * --save: Save figure to where `ifgramStack.h5` is. Leave blank for the plotting the figures
  * --fix: Bridge unwrapped phase. Leave blank for no fixing, just checking the corresponding connect components and pairs
  * --overwrite: Overwrite the dataset `unwrapPhase` in `ifgramStack.h5`
   
##
### Restore_PB.py
Restore the previous profile bridging results to .h5 dataset `unwrapPhase` if the last one was not satisfactory
* Required:
  * -d: Data: The absolute path of `ifgramStack.h5`

##
### Check_profile.py
Check the input profile and visualize it
* Required:
  * -d: Data: The absolute path of `ifgramStack.h5`
  * -p: Pair: Index of the pair to check the profile
  * -ps: ProfileStart: Starting point of the profile. Row, Col
  * -pe: ProfileEnd: Ending point of the profile. Row, Col
* Optional:
  * -v: Upperbound and lowerbound of the colorbar for unwrapped phase.

---
### Usage:
`ifgramStack.h5` is in `/data/project/mintpy/inputs`  

1. Use `Check_profile.py` first to see if the profile runs through the place you want
2. Use `Profile_Bridging.py` without the key `--fix` to check the detected pairs and corresponding connect components
3. Use `Profile_Bridging.py` with `--fix`, `--save` to perform profile bridging.
```python
# Check the profile.
python Check_profile.py -d /data/project/mintpy/inputs/ifgramStack.h5 -p 1 -ps 2000 2000 -pe 5000 2000

# Check the detected pairs and connect components
python Profile_Bridging.py -d /data/project/mintpy/inputs/ifgramStack.h5 -ps 2000 2000 -pe 5000 2000

# Start profile bridging 
python Profile_Bridging.py -d /data/project/mintpy/inputs/ifgramStack.h5 -ps 2000 2000 -pe 5000 2000 --fix --save

# If the previous profile bridging is bad, run:
python Restore_PB.py -d /data/project/mintpy/inputs/ifgramStack.h5
```
---
### Example:
#### Check_profile.py 
Before profile bridging  


After profile bridging