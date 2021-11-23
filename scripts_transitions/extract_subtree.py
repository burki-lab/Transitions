#!/usr/bin/python

## Mahwash Jamy
## Sep 2020

## This script extracts a subtree from a larger tree. It does so by finding the most recent common ancestor node of a set of tip labels provided (usually 2). It then extracts the whole subtree as specified by the node. 

## Usage: python extract_subtree.py [tree newick file] [list of taxa] [output file] 

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

OUT=sys.argv[3]

# write sub-tree. Formtat 5 indicates that you want internal and leaf branches + leaf names
print ancestor
t.write(format=5, outfile=OUT)
