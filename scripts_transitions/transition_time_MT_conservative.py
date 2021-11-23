#!/usr/bin/python

## Usage
## python transition_time_MT_conservative.py [labelled newick file] > [output file]  

## This script differs from transition_time_MT.py in that it is more conservative in what it counts as a transition.
## It is possible that several transitions are not actually transitions, but are contaminants, or Illumina sequences ending up in the wrong place (due to lack of phylogenetic signal).
## To overcome this, a transition is only counted, if it contains at least two seqs in the cluster.

from ete3 import Tree
import sys
import random

IN=sys.argv[1]

# read tree
t = Tree( IN )

# Get tree height
farthest, height = t.get_farthest_node()

# Print column headers
# print "distance_from_root\trelative_distance_from_root\tconfidence"

# Iterate through nodes and identify nodes annotated as T AND with parent nodes annotated as M 
# Iterate through nodes and identify nodes annotated as T AND with parent nodes annotated as ambiguous

for node in t.search_nodes(Env="T"):
    depth = node.get_distance(t)
    rel_depth = depth/height
    if not node.is_root() and not node.is_leaf():
	parent = node.up
	if getattr(parent, "Env") == "M":
	    print "M_to_T\t%s\t%s" % (depth, rel_depth)
	while getattr(parent, "Env") == "M|T" and (not parent.is_root()):
            parent = parent.up
            if getattr(parent, "Env") == "M":
		print "M_to_T\t%s\t%s\t" % (depth, rel_depth)
	if parent.is_root() and getattr(parent, "Env") == "M|T":
            number = random.randint(0,1)
            if number == 1:
                print "M_to_T\t%s\t%s\t" % (depth, rel_depth)
        while getattr(parent, "Env") == "T|M" and (not parent.is_root()):
            parent = parent.up
            if getattr(parent, "Env") == "M":
                print "M_to_T\t%s\t%s\t" % (depth, rel_depth)
        if parent.is_root() and getattr(parent, "Env") == "T|M":
            number = random.randint(0,1)
            if number == 1:
		print "M_to_T\t%s\t%s" % (depth, rel_depth)
    
