#!/usr/bin/python

## Usage
## python get_tip_labels_from_subtree.py [tree file] > [output file]  

from ete3 import Tree
import sys

IN=sys.argv[1]

# read tree
t = Tree( IN )

## get leaf names
for leaf in t:
  print leaf.name
