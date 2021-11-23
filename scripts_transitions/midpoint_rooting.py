#!/usr/bin/python

from ete3 import Tree
import sys

IN=sys.argv[1]

# read tree
t = Tree( IN )
# Calculate the midpoint node
R = t.get_midpoint_outgroup()
# and set it as tree outgroup
t.set_outgroup(R)

OUT=sys.argv[2]

# write tree. Formtat 5 indicates that you want internal and leaf branches + leaf names
t.write(format=5, outfile=OUT)

