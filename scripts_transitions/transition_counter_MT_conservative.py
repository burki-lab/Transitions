#!/usr/bin/python

## Usage
## python transition_counter_MT_conservative.py [labelled newick file] > [output file]  

## This script differs from transition_counter_MT.py in that it is more conservative in what it counts as a transition. 
## It is possible that several transitions are not actually transitions, but are contaminants, or Illumina sequences ending up in the rwong place (due to lack of phylogenetic signal).
## To overcome this, a transition is only counted, if it contains at least two seqs in the cluster.


from __future__ import division
from ete3 import Tree
import sys
import random

IN=sys.argv[1]

# read tree
t = Tree( IN )

# Iterate through nodes and identify nodes annotated as T AND with parent nodes annotated as M 
# Iterate through nodes and identify nodes annotated as T AND with parent nodes annotated as ambiguous

trans = 0

marine = []

for leaf in t:
        if "surface" in leaf.name:
            marine.append(leaf.name)
        if "deep" in leaf.name:
            marine.append(leaf.name)

tips = len(marine)


for node in t.search_nodes(Env="T"):
	if not node.is_root() and not node.is_leaf():
		parent = node.up
		if getattr(parent, "Env") == "M":
		    trans += 1
		while getattr(parent, "Env") == "M|T" and (not parent.is_root()):
                    parent = parent.up    
                    if getattr(parent, "Env") == "M":
                        trans += 1
                if parent.is_root() and getattr(parent, "Env") == "M|T":
                    number = random.randint(0,1)
                    if number == 1:
                        trans +=1
                while (getattr(parent, "Env") == "T|M") and (not parent.is_root()):
                    parent = parent.up
                    if getattr(parent, "Env") == "M":
                        trans += 1
                if parent.is_root() and getattr(parent, "Env") == "T|M":
                    number = random.randint(0,1)
                    if number == 1:
                        trans +=1

norm_trans = trans / tips

print "M_to_T\t%s\t%s" % (trans, norm_trans)
