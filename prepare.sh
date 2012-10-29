#!/usr/bin/env bash

################################################################################
### adapted from http://nmr.chem.uu.nl/~tsjerk/course/molmod/md.html
################################################################################

set -e

MINIM_MDP=minim.mdp
PR_TEMPLATE=pr.template
PR_MDP=pr.mdp
EQ_MDP=eq.mdp
SIM_MDP=gpu.mdp

pdb=$1
name=$(basename $pdb .pdb)
fixed=$name-fixed


################################################################################
### fix residues for gmx 4.0
################################################################################

fix-for-gmx40() {
$(dirname $0)/fix-for-gmx4.0.sh $pdb $fixed.pdb
}


################################################################################
### initial preparation of the topology
################################################################################

prepare-topology() {

pdb2gmx -f $fixed.pdb -o $name.gro -p $name.top -ff amber03
sed -i 's/\(#include "spc.itp"\)/;\1/' $name.top

}


################################################################################
### EM in vaccum
################################################################################

em-vaccum() {
cat <<EOF>$MINIM_MDP
define          = -DFLEXIBLE

integrator      = steep
emtol           = 1.0
nsteps          = -1
nstenergy       = 1
energygrps      = System

nstlist         = 0                     ; Frequency to update the neighbor list
ns_type         = simple                ; Method to determine neighbor list (simple, grid)
coulombtype     = cut-off               ; Treatment of long range electrostatic interactions
epsilon_rf      = 0
rcoulomb        = 1                     ; long range electrostatic cut-off
rvdw            = 1                     ; long range Van der Waals cut-off
constraints     = none                  ; Bond types to replace by constraints
pbc             = no                    ; Periodic Boundary Conditions (yes/no)
EOF

grompp -f $MINIM_MDP -c $name.gro -p $name.top -o $name-EM-vacuum.tpr
mdrun -v -deffnm $name-EM-vacuum -c $name-EM-vacuum.gro -p $name-EM-vacuum.tpr
}


################################################################################
### position-restrained MD
################################################################################

pr-equil() {

cat <<EOF>$PR_TEMPLATE
; VARIOUS PREPROCESSING OPTIONS
title                    = Position Restrained Molecular Dynamics
define                   = -DPOSRES

; RUN CONTROL PARAMETERS
integrator               = sd
dt                       = REGEX_DT
nsteps                   = 1000

; OUTPUT CONTROL OPTIONS
nstxout                  = 100
nstvout                  = 100
nstfout                  = 100
nstlog                   = 100
nstenergy                = 100
nstxtcout                = 100
energygrps               = System


; NEIGHBORSEARCHING PARAMETERS
nstlist                  = 0
ns_type                  = simple
pbc                      = no
rlist                    = 0

; OPTIONS FOR ELECTROSTATICS AND VDW
rcoulomb                 = 0
epsilon_rf               = 0
vdw-type                 = Cut-off
rvdw                     = 0

; Temperature coupling
tcoupl                   = no
tc-grps                  = System
tau_t                    = 1
ref_t                    = 370

; GENERATE VELOCITIES FOR STARTUP RUN
gen_vel                  = yes                 ; Assign velocities to particles by taking them randomly from a Maxwell distribution
gen_temp                 = 370               ; Temperature to generate corresponding Maxwell distribution
gen_seed                 = 42                  ; Seed for (semi) random number generation. Different numbers give different sets of velocities

; OPTIONS FOR BONDS
constraints              = none ;all-bonds          ; All bonds will be treated as constraints (fixed length)
EOF

pr_gro=$name-PR-0.00075.gro
pr_gro=$name-EM-vacuum.gro
# for dt in 0.0000000000001 0.000000001 0.00000001 0.0000001 0.000001 0.00001 0.0001 0.001; do
# hipin-42-ext
#  0.0000000000001 0.000000000001 0.00000000001 0.00000000005 0.00000000075
# 0.0000000001 0.000000001 0.00000001 0.0000001 0.000001 0.00001 0.0001 
for dt in 0.00001 0.0001 0.001; do
	sed "s/REGEX_DT/$dt/" $PR_TEMPLATE > $PR_MDP
	grompp -v -f $PR_MDP -c $pr_gro -p $name.top -o $name-PR-$dt.tpr
	mdrun -v -deffnm $name-PR-$dt
	# g_energy -f $name-PR-$dt.edr -o $name-PR-$dt-energies.xvg
	pr_gro=$name-PR-$dt
done
}

################################################################################
### equilibration (no constraints)
################################################################################

equil() {

cat <<EOF>$EQ_MDP
; RUN CONTROL PARAMETERS
integrator               = sd
ld_seed                  = 42
dt                       = 0.001
nsteps                   = 1000

; OUTPUT CONTROL OPTIONS
nstxout                  = 500
nstvout                  = 500
nstfout                  = 500
nstlog                   = 500
nstenergy                = 500
nstxtcout                = 500
energygrps               = System

; NEIGHBORSEARCHING PARAMETERS
nstlist                  = 0
ns-type                  = simple
pbc                      = no
rlist                    = 0

; OPTIONS FOR ELECTROSTATICS AND VDW
coulombtype              = cut-off
rcoulomb                 = 0
epsilon_rf               = 0
vdw-type                 = Cut-off
rvdw                     = 0

; Temperature coupling
tcoupl                   = no
tc-grps                  = system
tau_t                    = 1
ref_t                    = 370

; Pressure coupling
Pcoupl                   = no

; GENERATE VELOCITIES FOR STARTUP RUN
gen_vel                  = yes    ; Assign velocities to particles by taking them randomly from a Maxwell distribution
gen_temp                 = 370.0  ; Temperature to generate corresponding Maxwell distribution
gen_seed                 = 42   ; Seed for (semi) random number generation.


; OPTIONS FOR BONDS
;constraints              = all-bonds

EOF

grompp -v -f $EQ_MDP -c $name-PR-0.001.gro -p $name.top -o $name-equil.tpr
mdrun -v -deffnm $name-equil

}


################################################################################
### equilibration (with constraints)
################################################################################

equil-constr() {

cat <<EOF>$EQ_MDP
; RUN CONTROL PARAMETERS
integrator               = sd
ld_seed                  = 42
dt                       = 0.002
nsteps                   = 5000

; OUTPUT CONTROL OPTIONS
nstxout                  = 250
nstvout                  = 250
nstfout                  = 250
nstlog                   = 250
nstenergy                = 250
nstxtcout                = 250
xtc-grps                 = System

; NEIGHBORSEARCHING PARAMETERS
nstlist                  = 0
ns-type                  = simple
pbc                      = no
rlist                    = 0

; OPTIONS FOR ELECTROSTATICS AND VDW
coulombtype              = cut-off
rcoulomb                 = 0
epsilon_rf               = 0
vdw-type                 = Cut-off
rvdw                     = 0

; Temperature coupling
tcoupl                   = no
tc-grps                  = System
tau_t                    = 1
ref_t                    = 370

; Pressure coupling
Pcoupl                   = no

; GENERATE VELOCITIES FOR STARTUP RUN
gen_vel                  = yes    ; Assign velocities to particles by taking them randomly from a Maxwell distribution
gen_temp                 = 330.0  ; Temperature to generate corresponding Maxwell distribution
gen_seed                 = 42   ; Seed for (semi) random number generation.


; OPTIONS FOR BONDS
constraints              = hbonds

EOF

grompp -v -f $EQ_MDP -c $name-equil.gro -p $name.top -o $name-equil-constr.tpr
mdrun -v -deffnm $name-equil-constr

}


################################################################################
### prep for GPU
################################################################################

prep-for-gpu() {

cat <<EOF>$SIM_MDP
; RUN CONTROL PARAMETERS
integrator               = sd
ld_seed                  = 42
dt                       = 0.002
nsteps                   = 500000

; OUTPUT CONTROL OPTIONS
nstxout                  = 25000
nstvout                  = 25000
nstfout                  = 25000
nstlog                   = 25000
nstenergy                = 25000
nstxtcout                = 25000
xtc-grps                 = System

; NEIGHBORSEARCHING PARAMETERS
nstlist                  = 0
ns-type                  = simple
pbc                      = no
rlist                    = 0

; OPTIONS FOR ELECTROSTATICS AND VDW
coulombtype              = cut-off
rcoulomb                 = 0
epsilon_rf               = 0
vdw-type                 = Cut-off
rvdw                     = 0

; Temperature coupling
tcoupl                   = no
tc-grps                  = System
tau_t                    = 1
ref_t                    = 370

; Pressure coupling
Pcoupl                   = no

; GENERATE VELOCITIES FOR STARTUP RUN
gen_vel                  = yes    ; Assign velocities to particles by taking them randomly from a Maxwell distribution
gen_temp                 = 330.0  ; Temperature to generate corresponding Maxwell distribution
gen_seed                 = 42   ; Seed for (semi) random number generation.


; OPTIONS FOR BONDS
constraints              = hbonds

EOF

grompp -v -f $SIM_MDP -c $name-equil-constr.gro -p $name.top -o $name-gpu.tpr
}


fix-for-gmx40

prepare-topology
em-vaccum

pr-equil

equil

equil-constr

prep-for-gpu
rm -f \#*