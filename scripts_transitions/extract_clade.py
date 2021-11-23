#!/usr/bin/python

## Mahwash Jamy
## Sep 2020

## This script extracts a clade from a larger tree. It does so by finding the most recent common ancestor node of a set of tip labels containing the clade name provided. It then extracts the whole subtree as specified by the node. 

## Usage: python extract_subtree.py [tree newick file] [clade name] [output file] 

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

## prune the tree to remove everything else
t.prune(ancestor)

OUT=sys.argv[3]

# write sub-tree. Formtat 5 indicates that you want internal and leaf branches + leaf names
# print ancestor
t.write(format=5, outfile=OUT)
