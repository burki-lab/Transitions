#!/usr/bin/python
  
from ete3 import Tree
import sys

DIR="env_seq/taxonomy"

IN=DIR + sys.argv[1]
NAMES=DIR + sys.argv[2]

with open(NAMES) as f:
    TIPS = f.read().splitlines()
OUT=sys.argv[3]

t = Tree( IN )
t.prune(TIPS)
t.unroot()
t.write(format=5, outfile=OUT)
