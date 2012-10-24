
def getopts():
    p = argparse.ArgumentParser()
    p.add_argument('-f', '--inpdb')
    p.add_argument('-o', '--outpdb')

    return p.parse_args()


def getAtomStr(data, lineNo):
    """
    data :: [str]
    lineNo :: int
    """
    return data[lineNo][12:16].strip()

def setAtomStr(data, lineNo, atomStr):
    """
    data :: [str]
    lineNo :: int
    atomStr :: str
    """

    prefix = data[lineNo][:12]
    suffix = data[lineNo][16:]
    data[lineNo] = prefix + ('%-4s' % atomStr) + suffix
    return data

def getResidueNum(data, lineNo):
    return int(data[lineNo][22:27])

def getAtomNum(data, lineNo):
    return int(data[lineNo][6:11])

def getResidueName(data, lineNo):
    return data[lineNo][17:20]

