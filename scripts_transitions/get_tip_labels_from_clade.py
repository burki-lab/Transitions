#!/usr/bin/python

## Usage
## python get_tip_labels_from_clade.py [tree file] [clade name] > [output file]  

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

## get leaf names
for leaf in t:
  print leaf.name
