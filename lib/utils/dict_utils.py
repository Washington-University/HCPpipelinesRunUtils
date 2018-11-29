#!/usr/bin/env python3

"""dict_utils.py: Some simple and hopefully useful dictionary utilities."""

# import of built-in modules
import sys

# import of third party modules
pass

# import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2018, The Connectome Coordination Facility"

def print_as_table(d, file=sys.stdout):

	# figure out longest length of key
	max_key_length = 0
	for k in d.keys():
		if len(str(k)) > max_key_length:
			max_key_length = len(str(k))

	for k in d.keys():
		if 'password' in k.lower():
			value = '******'
		else:
			value = d[k]
			
		print("{keyval:>{width}} : {val}".format(keyval=k, val=value, width=max_key_length+1))
			

	
