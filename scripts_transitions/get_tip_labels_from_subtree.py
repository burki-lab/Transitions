#!/usr/bin/python

## Usage
## python get_tip_labels_from_subtree.py [tree file] [list of taxa to specify node of subtree] > [output file]  

from ete3 import Tree
import sys

IN=sys.argv[1]
NAMES=sys.argv[2]

# read tree
t = Tree( IN )

# Get the node/subtree that contains both the specified leaves
with open(NAMES) as f:
    TIPS = f.read().splitlines()

ancestor = t.get_common_ancestor(TIPS)

## prune the tree to remove everything else
t.prune(ancestor)

## get leaf names
for leaf in t:
  print leaf.name
