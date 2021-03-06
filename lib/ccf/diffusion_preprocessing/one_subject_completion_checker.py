#!/usr/bin/env python3

"""${HCP_RUN_UTILS}/lib/ccf/diffusion_preprocessing/one_subject_completion_checker.py

Defines the class used for completion checking of diffusion preprocessing

"""

# import of built-in modules
import sys

# import of third-party modules

# import of local modules
import ccf.one_subject_completion_checker as one_subject_completion_checker
import ccf.subject as ccf_subject
import utils.my_argparse as my_argparse

# authorship information
__author__ = "The Connectome Coordination Facility"
__copyright__ = "Copyright 2017-2019, The Connectome Coordination Facility"


class OneSubjectCompletionChecker(one_subject_completion_checker.OneSubjectCompletionChecker):
	"""Used for completion checking of diffusion preprocessing

	"""
	
	def __init__(self):
		super().__init__()

	@property
	def processing_name(self):
		return 'DiffusionPreprocessing'

	
if __name__ == "__main__":

	parser = my_argparse.MyArgumentParser(
		description="Program to check for completion of Diffusion Preprocessing for a single subject.")
	
	# mandatory arguments
	parser.add_argument('-w', '--working-dir', dest='working_dir', required=True, type=str)
	parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
	parser.add_argument('-c', '--classifier', dest='classifier', required=True, type=str)
	parser.add_argument('-f', '--fieldmap', dest='fieldmap', required=False, type=str, default='NONE')

	# optional arguments
	parser.add_argument('-v', '--verbose', dest='verbose', action='store_true',
						required=False, default=False)
	parser.add_argument('-o', '--output', dest='output', required=False, type=str)
	parser.add_argument('-a', '--check-all', dest='check_all', action='store_true',
						required=False, default=False)

	# parse the command line arguments
	args = parser.parse_args()

	# check the specified subject for diffusion preprocessing completion
	subject_info = ccf_subject.SubjectInfo(
		project='irrelevant',
		subject_id=args.subject,
		classifier=args.classifier)
	completion_checker = OneSubjectCompletionChecker()

	if args.output:
		processing_output = open(args.output, 'w')
	else:
		processing_output = sys.stdout

	if completion_checker.is_processing_complete(
			working_dir=args.working_dir,
			fieldmap=args.fieldmap,
			subject_info=subject_info,
			verbose=args.verbose,
			output=processing_output,
			short_circuit=not args.check_all):
		print("Exiting with 0 code - Completion Check Successful")
		exit(0)
	else:
		print("Exiting with 1 code - Completion Check Unsuccessful")
		exit(1)
