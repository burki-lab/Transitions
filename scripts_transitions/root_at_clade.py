#!/usr/bin/python

## Mahwash Jamy
## Oct 2020

## This script roots a tree at a specified node. The node is specified as the ancestor of two tips 

## Usage: python root_at_clade.py [tree newick file] [clade name] [output file] 

from ete3 import Tree
import sys

IN=sys.argv[1]
CLADE=sys.argv[2]

TIPS = []

# read tree
t = Tree( IN )

# Get the list of tips that contain the clade name
for leaf in t:
	if CLADE in leaf.name:
		TIPS.append(leaf.name)	

ancestor = t.get_common_ancestor(TIPS)

t.set_outgroup(ancestor)

OUT=sys.argv[3]

# write sub-tree. Formtat 5 indicates that you want internal and leaf branches + leaf names
t.write(format=5, outfile=OUT)
