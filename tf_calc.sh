#!/bin/bash

i=$1
j=$2
k=$3
l=$4
m=$5

rmin=0.6    # where the delta region begins with respect to the center of the box (where we would like Fth to begin)
rmax=2.1    # where the Fth will end with respect to center of box
rbox=5.8    # length of box in x direction
rref=2.9    # reference point (center of box) as measure in the positive x direction
lc=125       # number of bins for density calculation
rstep=$(echo $rbox/$lc | bc -l) # dx for density calc and Fth

r_cut=$(echo $rmin| bc -l)
rm_c=$(echo $rmax | bc -l)
echo $r_cut, $rm_c

prep_sys=$i
case $prep_sys in
 [0]*)

if [ ! -f F_th_step0 ]; then 
   seq -f%e 0.0 $rstep $rbox | awk '{print $1, "0.0", "0.0"}' > F_th_step0
fi
cp F_th_step0 tabletf_WCG.xvg

# check if $lc is an odd number. if not, exit

#if [ $(($lc % 2 == 0)) ]
#then
#
#	echo "Please make lc an odd number... (e.g., 151)"
#	exit 1
#else
#
#	continue
#fi

echo "Beginning preliminary md simulation without thermodynamic force..."
sleep 1
gmx mdrun -v

 [1]*)

if [ -f tabletf_WCG.xvg ]; then
   awk 'BEGIN{OFS="\t"}(NR>9){print $1, $2, $3}' tabletf_WCG.xvg > F_th_step0
fi
;;
esac

echo "Calculating density..."
sleep 1

echo "2" > t_c; gmx density -d X -sl $lc -f traj_comp.xtc -o dens.xvg < t_c

echo "Printing dens.out..."
sleep 1

awk 'BEGIN{OFS="\t"}(NR>24){print $1, $2}' dens.xvg > dens.out

# delete last line of density tables
# this avoids problems when calculating Fth
# to the end of the box

sed -i '$d' dens.out

## folding and symmetrizing density for smoothing:

awk '{d=$1-'$rref'; print ((d>0)?d:-d), $2}' dens.out >  symDens

# duplicate the center line (0) so that there is again an even number
# of lines in the density table

sed -i 's/0 .*/&\n&/' symDens

# split the symmetrized density and average

split -l $(( ($lc-1)/2 )) symDens
awk '{printf "%10f %10f\n", $1, $2}' xaa | sort -g > x1
awk '{printf "%10f %10f\n", $1, $2}' xab | sort -g > x2
paste x1 x2 | awk '{print $1,($2+$4)/2.0}' > symDensAverage

# print averaged dens profile in region of Fth calculation only

awk '{if(($1>=('$r_cut')) && ($1<=('$rm_c'))) print $1,$2}' symDensAverage > dens_hy

# interpolate between Fth region points
# and further take the derivative of this interpolated curve.
# this gives us our contribution to the Fth for this iteration

echo "Beginning interpolation..."
sleep 1

./smooth_dens.sh

cp derivative d_s
cp potential p_s

echo "#","manually gen. Thermodyn. Force approx." > $m.xvg
echo "#","Parameter:">> $m.xvg
echo "#","start hy-region:", $rmin >> $m.xvg
echo "#","end of hy-region:",$rmax >> $m.xvg
echo "#","start tf: from xsplit" >> $m.xvg
echo "#","start hy-region:", $rmin >> $m.xvg
echo "#","end of hy-region:",$rmax >> $m.xvg
echo "#" >> $m.xvg
echo "#" >> $m.xvg

pmax=$(head -n 1 p_s | awk '{print $2}')
pmin=$(tail -n 1 p_s | awk '{print $2}')

# build d0, d1, d2 regions of table

awk '{if ($1 < '$r_cut') print $1, 0.0}' F_th_step0 > d0

awk '{print $1}' dens_hy > temp1
awk '{print $2}' d_s > temp2
paste temp1 temp2 > d1

temp3=$(tail -n 1 d1 | awk '{print $1+0.005}')

awk '{if ($1 > '$temp3') print $1, 0.0}' F_th_step0 > d2

# build p0, p1, p2 regions of table

awk '{if ($1 < '$r_cut') print $1, '$pmax'}' F_th_step0 > p0

awk '{print $1}' dens_hy > temp1
awk '{print $2}' p_s > temp2
paste temp1 temp2 > p1

temp4=$(tail -n 1 p1 | awk '{print $1+0.005}')

awk '{if ($1 > '$temp4') print $1, '$pmin'}' F_th_step0 > p2

# build tf and pot tables and combine them into dens_mix

cat d0 d1 d2 > d_m
cat p0 p1 p2 > p_m
paste p_m d_m | awk '{print $1,$2,$4}' > table

paste F_th_step0 table | awk 'BEGIN{OFS="\t"}{printf("%e %e %e\n",$1,($2-$5),($3-$6)) }' >> $m.xvg

cp $m.xvg tabletf_WCG_$m.xvg
cp $m.xvg tabletf_WCG.xvg

gmx mdrun -v

echo "Printing SOL.dens_s?.xvg..."
sleep 2
echo "2" > t_c; gmx density -d X -f traj_comp.xtc -o SOL.dens_$m.xvg < t_c

# CLEAN UP
rm p? d? x? x?? \#*
rm SOL.dpot.*
rm p_m d_m
rm d_s d_s_t 
rm t_c
rm s?.xvg s??.xvg
rm ref_dens
rm ref_dens_t calc_dens*
rm s.d.o 
rm p_s
rm ref_t 
rm calc_t 
rm dens.ref
