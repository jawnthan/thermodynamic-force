#!/bin/bash

source /home/mi/johnwhittake/bin/gmx_5.1-localThermostat/bin/GMXRC

i=$1
j=$2

case $3 in
 [0]*)
rm F_th_* tabletf* SOL.dens.s* dens_mix_* \#* SOL.dens_s*.xvg
./tf_calc.sh 0  dens.SOL.out SOL.dens.out s0 2

;;
 [1]*)
rm F_th_* tabletf* SOL.dens.s* dens_mix_* \#* SOL.dens_s*.xvg
gmx grompp -f md.mdp -c conf.gro -p ../../build/adress-topol.top -n index.ndx
./tf_calc.sh 0  dens.SOL.out SOL.dens.out s0 2

for z in `seq $i $j`; do
./tf_calc.sh 3  dens.SOL.out SOL.dens.out s$z 2
done

;;
 [2]*)
for z in `seq $i $j`; do
./tf_calc.sh 3  dens.SOL.out SOL.dens.out s$z 2
done

;;
esac


