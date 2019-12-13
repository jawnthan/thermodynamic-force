#!/bin/bash

source /home/mi/johnwhittake/bin/gmx_5.1-localThermostat/bin/GMXRC

i=$1
j=$2

case $3 in
 [1]*)
rm initial* tabletf* dens.* \#* SOL.dens_s*.xvg
gmx grompp -f md.mdp -c conf.gro -p ../../../build/adress-topol.top -n index.ndx
./calc_tf.sh 0 s0

for z in `seq $i $j`; do
./calc_tf.sh 1 s$z
done

;;
 [2]*)
for z in `seq $i $j`; do
./calc_tf.sh 1 s$z
done

;;
esac


