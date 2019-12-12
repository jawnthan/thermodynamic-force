#!/usr/bin/env python

import sys

from numpy import *
from scipy.signal import savgol_filter
from scipy import integrate
from scipy import interpolate
import matplotlib.pyplot as plt

f = file('dens_hy', 'r')

tgt = loadtxt(f, usecols=(0,1))

r     = tgt[:,0]
dens  = tgt[:,1]
start = tgt[0,0]
stop  = tgt[-1,0]

T   = 298
kbT = -1.0*0.00831451*T
prefac = 0.001
rbox   = 5.8

rnew = linspace(start, stop, num=500)

tck        = interpolate.splrep(r, dens, s=0)
smoothDens = interpolate.splev(rnew, tck, der=0)
derivative = interpolate.splev(rnew, tck, der=1)

pot     = smoothDens*kbT*prefac
tf      = derivative*prefac

step = (rnew[-1] - rnew[-2])

first   = arange(0.0, start, step)
second  = arange(stop+step, rbox, step)

first0  = zeros(len(first))
second0 = zeros(len(second))

first_pot  = full(len(first), pot[0])
second_pot = full(len(second), pot[-1])

x     = concatenate((first, rnew, second))
y_tf  = concatenate((first0, tf, second0))
y_pot = concatenate((first_pot, pot, second_pot))

SPL = column_stack((rnew, smoothDens))
savetxt('smoothDens', SPL)

DAT = column_stack((x, y_tf))
savetxt('derivative', DAT)

POT = column_stack((x, y_pot))
savetxt('potential', POT)

#plt.plot(r, dens) 
#plt.plot(rnew, smoothDens)
#plt.show()
#
#plt.plot(rnew, pot)
#plt.plot(rnew, tf)
#plt.show()
