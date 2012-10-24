#!/usr/bin/env python

import os
import subprocess
import tempfile
import argparse


def tleap_script(pdbpath, destpath, leaprc):
    return """
source %(leaprc)s
x = loadPdb %(pdbpath)s
savePdb x %(destpath)s
quit
""" % { 'leaprc' : leaprc,
        'pdbpath' : pdbpath,
        'destpath' : destpath
        }



def run_tleap(script):

    # save the tleap script
    fd, path = tempfile.mkstemp()
    os.write(fd, script)
    os.close(fd)

    cmd = ['tleap', '-f', path]
    print 'Executing:', ' '.join(cmd)
    subprocess.check_call(cmd)
    os.unlink(path)


def getopts():
    p = argparse.ArgumentParser()
    p.add_argument('-f', '--inpdb', help='Input PDB file')
    p.add_argument('-o', '--outpdb', help='Output PDB file')
    p.add_argument('-s', '--source', default='oldff/leaprc.ff03', help='leaprc file to source [oldff/leaprc.ff03')

    return p.parse_args()


if __name__ == '__main__' :
    opts = getopts()
    script = tleap_script(opts.inpdb, opts.outpdb, opts.source)
    run_tleap(script)
