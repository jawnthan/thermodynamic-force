#!/usr/bin/env python

import sys

from numpy import *
from scipy.signal import savgol_filter
from scipy import integrate
from scipy import interpolate
import matplotlib.pyplot as plt

f = file('symDensAverage', 'r')

tgt = loadtxt(f, usecols=(0,1))

r     = tgt[:,0]
dens  = tgt[:,1]

start = tgt[0,0]
stop  = tgt[-1,0]

rbox  = 5.8
rmin  = 0.6
T   = 298
kbT = -1.0*0.00831451*T
prefac = 0.001

rnew = linspace(start, stop, num=500)

tck         = interpolate.splrep(r, dens)
dens_spline = interpolate.splev(rnew, tck, der=0)
derivative  = interpolate.splev(rnew, tck, der=1)

pot     = dens_spline*kbT*prefac
tf      = derivative*prefac

step = (rnew[-1] - rnew[-2])

rnew1    = arange(stop+step, rbox, step)

tf2      = arange(stop+step, rbox, step)
zero_tf  = zeros(len(tf2))

#pot1     = full(len(pot), pot[0])
pot3     = full(len(zero_tf), pot[-1])

x     = concatenate((rnew, rnew1))
y_tf  = concatenate((tf, zero_tf))
y_pot = concatenate((pot, pot3))

SPL = column_stack((rnew, dens_spline))
savetxt('smoothDens', SPL)

###### TF build ######

DAT = column_stack((x, y_tf))

# if the first column < rmin, make second column 0.0

DAT[:,1][DAT[:,0] < rmin] = 0.0

savetxt('derivative', DAT)

##### POT build #####

POT = column_stack((x, y_pot))

# if the first column < rmin, make second column pot 1

POT[:,1][POT[:,0] < rmin] = pot[0]
savetxt('potential', POT)

#plt.plot(r, dens) 
#plt.plot(rnew, smoothDens)
#plt.show()
#
#plt.plot(rnew, pot)
#plt.plot(rnew, tf)
#plt.show()
