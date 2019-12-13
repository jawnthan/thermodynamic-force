#!/bin/bash

i=$1
j=$2

rmin=0.6    # where the delta region begins with respect to the center of the box (where we would like Fth to begin)
rmax=2.9    # where the Fth will end with respect to center of box
rbox=5.8    # length of box in x direction
rref=2.9    # reference point (center of box) as measure in the positive x direction
lc=67       # number of bins for density calculation
rstep=$(echo $rbox/$lc | bc -l) # dx for density calc and Fth

r_cut=$(echo $rmin| bc -l)
rm_c=$(echo $rmax | bc -l)
echo $r_cut, $rm_c

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

case $i in
 [0]*)

### calculate brand new tf option ###########################################

if [ ! -f initial_table ]; then 
   seq -f%e 0.0 $rstep $rbox | awk '{print $1, "0.0", "0.0"}' > initial_table
fi

cp initial_table tabletf_WCG.xvg


echo "Beginning preliminary md simulation without tf = 0..."
sleep 1
gmx mdrun -v

echo "Calculating density..."
sleep 1

echo "2" > t_c; gmx density -d X -sl $lc -f traj_comp.xtc -o dens.xvg < t_c

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

# awk '{if(($1>=('$r_cut')) && ($1<=('$rm_c'))) print $1,$2}' symDensAverage > dens_hy

# interpolate between Fth region points
# and further take the derivative of this interpolated curve.
# this gives us our contribution to the Fth for this iteration

echo "Beginning interpolation..."
sleep 1

./smooth_dens.sh

echo "#","manually gen. Thermodyn. Force approx." > $j.xvg
echo "#","Parameter:">> $j.xvg
echo "#","start hy-region:", $rmin >> $j.xvg
echo "#","end of hy-region:",$rmax >> $j.xvg
echo "#","start tf: from xsplit" >> $j.xvg
echo "#","start hy-region:", $rmin >> $j.xvg
echo "#","end of hy-region:",$rmax >> $j.xvg
echo "#" >> $j.xvg
echo "#" >> $j.xvg

paste potential derivative | awk '{print $1,$2,$4}' > table

awk '{print $1, 0.0, 0.0}' table > initial_table

paste initial_table table | awk 'BEGIN{OFS="\t"}{printf("%e %e %e\n",$1,($2-$5),($3-$6)) }' >> $j.xvg

cp $j.xvg tabletf_WCG_$j.xvg
cp $j.xvg tabletf_WCG.xvg

gmx mdrun -v

echo "Printing SOL.dens_s?.xvg..."
sleep 1

echo "2" > t_c; gmx density -d X -f traj_comp.xtc -o SOL.dens_$j.xvg < t_c

# CLEAN UP
rm p? d? x? x?? \#*
rm SOL.dpot.*
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

;;
 [1]*)

### resume TF calculation option ##############################################
	 
if [ -f tabletf_WCG.xvg ]; then
   awk 'BEGIN{OFS="\t"}(NR>9){print $1, $2, $3}' tabletf_WCG.xvg > initial_table
fi

echo "Calculating density..."
sleep 1

echo "2" > t_c; gmx density -d X -sl $lc -f traj_comp.xtc -o dens.xvg < t_c

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

echo "#","manually gen. Thermodyn. Force approx." > $j.xvg
echo "#","Parameter:">> $j.xvg
echo "#","start hy-region:", $rmin >> $j.xvg
echo "#","end of hy-region:",$rmax >> $j.xvg
echo "#","start tf: from xsplit" >> $j.xvg
echo "#","start hy-region:", $rmin >> $j.xvg
echo "#","end of hy-region:",$rmax >> $j.xvg
echo "#" >> $j.xvg
echo "#" >> $j.xvg

paste potential derivative | awk '{print $1,$2,$4}' > table

paste initial_table table | awk 'BEGIN{OFS="\t"}{printf("%e %e %e\n",$1,($2-$5),($3-$6)) }' >> $j.xvg

cp $j.xvg tabletf_WCG_$j.xvg
cp $j.xvg tabletf_WCG.xvg

gmx mdrun -v

echo "Printing SOL.dens_s?.xvg..."
sleep 1
echo "2" > t_c; gmx density -d X -f traj_comp.xtc -o SOL.dens_$j.xvg < t_c

# CLEAN UP
rm p? d? x? x?? \#*
rm SOL.dpot.*
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
;;
esac
