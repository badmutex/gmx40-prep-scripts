#!/usr/bin/env bash

set -e

name=$1
shift

[ -z $1 ] && devid=0 || devid=$1


mdrun-gpu -v -s $name-gpu.tpr -deffnm $name-gpu -device "OpenMM:force-device=yes,deviceid=$devid"

gmxcheck -f $name-gpu.xtc
