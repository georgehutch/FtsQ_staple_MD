#!/bin/bash
#SBATCH --job-name=prodMD_ftsQ
#SBATCH -p fargpu
#SBATCH --gres=gpu:2
#SBATCH --time=144:00:00
#SBATCH --nodes=1
#SBATCH --exclusive  

module load amber/20
echo "--------- Starting ------------"
echo $(date)
#
# 2. Set directories

export MYDIR="$HOME/MD/FtsQ/FtsQ-B-STP"
export MYEXE="pmemd.cuda"

cd $MYDIR
pwd

mkdir MD
cp ./* ./MD
cd MD

export PROTEIN="ftsQ-B_stp"
echo $PROTEIN
echo "Starting minsolv"
#read user1
pmemd.cuda -O -i minsolv.i -o minsolv.log -p $PROTEIN.prmtop -c $PROTEIN.inpcrd -ref $PROTEIN.inpcrd -r minsolv.rst
old=minsolv

pmemd -O -i mdsolvpmemd.i -o mdsolvpmemd.log -p $PROTEIN.prmtop -c $old.rst -ref $PROTEIN.inpcrd -x mdsolvpmemd.nc -r mdsolvpmemd.rst
old=mdsolvpmemd

pmemd.cuda -O -i mdsolvcuda.i -o mdsolvcuda.log -p $PROTEIN.prmtop -c $old.rst -ref $PROTEIN.inpcrd -x mdsolvcuda.nc -r mdsolvcuda.rst
old=mdsolvcuda

MYEXE="pmemd.cuda"
for name in min heat eq_npt; do
        echo "Starting $name"
        if [ $name = min ] ; then
                MYEXE="pmemd.cuda"
        fi

	$MYEXE -O -i $name.i -o $name.log -p $PROTEIN.prmtop -c $old.rst -ref $PROTEIN.inpcrd -x $name.nc -r $name.rst
        old=$name
        MYEXE="pmemd.cuda"
done

old="eq_npt" ##
x0=0


ln -s $old.rst md$x0.rst

int=10
x=`expr $x0 + $int`
X=100
for x in `seq $x $int $X`; do
        pmemd.cuda -O -i md.i -o md$x.log -p $PROTEIN.prmtop -c md$x0.rst -x md$x.nc -r md$x.rst
        x0=$x
done
