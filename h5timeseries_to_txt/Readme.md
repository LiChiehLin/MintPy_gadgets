# Convert .h5 timeseries from MintPy to .txt file
This is a Matlab code designed to convert `MintPy` LOS timeseries data into `.txt` format.  
Sometimes, it is just easier to **share/process/work** with data in text files...
  

---
##### Input variable:  
  * h5TS: String. The path and filename to your timeseries h5 file.
  * h5TempMask: String. The path and filename to your temporal coherence mask (Or any mask with the same spatial coverage)
  * Bbox: 4x1 opr 1x4 vector. The coordinates to make a subset of the timeseries. [W,E,S,N].
    - `Bbox(1) = Min Longitude`
    - `Bbox(2) = Max Longitude`
    - `Bbox(3) = Min Latitude`
    - `Bbox(4) = Max Latitude`

##### Output variable:
The code will create a folder named `timeseries_textfile/` where this code is executed and the converted text file will be stored in it.  
The output text file is in the format shown below (displacement unit should be in meters):
| Lon.  | Lat. | 20160927 | 20161009 | 20161021 | 20161102 | ... | End date |
| -------------| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |
| 120.1 | 23.1 | 0 | 0.01  | 0.02  | 0.03  | ...  | 0.20  |
| 120.1 | 23.2 | 0 | 0.02  | 0.03  | 0.04  | ...  | 0.23  |
| ... | ... | ... | ...  | ...  | ...  | ...  | ...  |

Each row is the displacement history of that pixel.

---

Note that: According to the way this code is designed, you can only put your inputs in the following **3 ways**.
1. Timeseries. **1 input**.  
   Output text file: `[h5 timeseries filename].txt`
2. Timeseries and Mask. **2 inputs**  
   Output text file: `[h5 timeseries filename]_masked.txt`
3. Timeseries, Mask and Bbox. **3 inputs**  
   Output text file: `[h5 timeseries filename]_masked_subset.txt`

Does not support the combination of `Timeseries` and `Bbox`.

---

### Example:
```matlab
h5TS = '/data/mintpy/timeseries_ERA5.h5';
h5TempMask = '/data/mintpy/maskTempCoh.h5';
Bbox = [120,121,22,23]; % [Min Lon, Lax Lon, Min Lat, Max Lat]

h5TS_to_Text(h5TS,h5TempMask,Bbox);
```

