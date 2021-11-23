#!/usr/bin/python

## Mahwash Jamy
## Feb 2021

## This script converts newick files to nexus files with a tranlsated taxon list, which is suitable as input for BayesTraits.

## Usage: python newick_to_nexus.py [tree newick file] [output file]

import dendropy
import sys

IN=sys.argv[1]
OUT=sys.argv[2]

ds = dendropy.DataSet()
taxon_namespace = dendropy.TaxonNamespace()
ds.attach_taxon_namespace(taxon_namespace)

ds.read(path=IN, schema="newick", preserve_underscores=True)

ds.write(path=OUT, schema="nexus", suppress_taxa_blocks=True, translate_tree_taxa=True, unquoted_underscores=True)
