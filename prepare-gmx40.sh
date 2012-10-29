#!/usr/bin/env bash

set -e

inputpdb=$1

locate() {
	name=$1
	echo $(dirname $0)/$name
}

REMOVE_HBONDS=$(locate removeHydrogens.py)
PASS_THROUGH_TLEAP=$(locate passThroughTleap.py)
RESIDUE_SUBSTITUTIONS=$(locate residueSubstitutions.py)
FIX_HYDROGENS=$(locate fixHydrogens.py)


$REMOVE_HBONDS -i $inputpdb -o 00-nohydrogens.pdb
$PASS_THROUGH_TLEAP -f 00-nohydrogens.pdb -o 01-tleap.pdb
sed -i '/^TER$/d' 01-tleap.pdb
$RESIDUE_SUBSTITUTIONS -i 01-tleap.pdb -o 02-subst.pdb \
	-a 'LYS     1' 'NLYP    1' \
	-a 'ALA     1' 'NALA    1' \
	-a ' LYS ' ' LYP '
$FIX_HYDROGENS -f 02-subst.pdb -o 03-fixed.pdb
pdb2gmx -f 03-fixed.pdb -ff amber03
