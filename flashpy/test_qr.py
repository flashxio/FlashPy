import flashpy as fp
import time
import numpy as np
import scipy as sp
fp.init_flashpy()

for k in xrange(4, 9):
    arr = np.random.normal(size=[pow(10,k), 32])
    print(arr.shape)
    fp_arr = fp.array(arr)
    start = time.time()
    Q, _ = sp.linalg.qr(arr, mode='economic')
    end = time.time()
    print("scipy: " + str(end - start))
    start = time.time()
    Q, _ = fp.linalg.qr(fp_arr)
    end = time.time()
    print("FlashPy: " + str(end - start))
