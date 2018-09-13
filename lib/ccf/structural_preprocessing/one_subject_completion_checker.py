#!/usr/bin/env python3

# import of built-in modules
import os
import sys

# import of third-party modules

# import of local modules
import ccf.one_subject_completion_checker as one_subject_completion_checker
import ccf.subject as ccf_subject
import utils.my_argparse as my_argparse
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017-2018, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(one_subject_completion_checker.OneSubjectCompletionChecker):

	def __init__(self):
		super().__init__()

	def list_of_expected_files(self, working_dir, subject_info):

		hcp_run_utils = os_utils.getenv_required('HCP_RUN_UTILS')
		f = open(hcp_run_utils + os.sep + 'StructuralPreprocessing' + os.sep + 'ExpectedOutputFiles.CCF.txt')
		list_from_file = f.readlines()

		l = []
		
		for name in list_from_file:
			# remove any comments (anything after a # on a line)
			filename = name.split('#', 1)[0]
			# remove leading and trailing whitespace
			filename = filename.strip()      
			if filename:
				# replace internal whitespace with separator '/' or '\'
				filename = os.sep.join(filename.split())
				# replace subject id placeholder with actual subject id
				filename = filename.replace("{subjectid}", subject_info.subject_id)
				# prepend working directory and subject id directory
				filename = os.sep.join([working_dir, subject_info.subject_id, filename])
				l.append(filename)
		
		return l

if __name__ == "__main__":

	parser = my_argparse.MyArgumentParser(
		description="Program to check for completion of Structural Preprocessing.")

	# mandatory arguments
	# parser.add_argument('-p', '--project', dest='project', required=True, type=str)
	parser.add_argument('-w', '--working-dir', dest='working_dir', required=True, type=str)
	parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
	parser.add_argument('-c', '--classifier', dest='classifier', required=True, type=str)

	# optional arguments
	parser.add_argument('-v', '--verbose', dest='verbose', action='store_true',
						required=False, default=False)
	parser.add_argument('-o', '--output', dest='output', required=False, type=str)
	parser.add_argument('-a', '--check-all', dest='check_all', action='store_true',
						required=False, default=False)
	# parse the command line arguments
	args = parser.parse_args()
  
	# check the specified subject for structural preprocessing completion
	# subject_info = ccf_subject.SubjectInfo(args.project, args.subject, args.classifier)
	subject_info = ccf_subject.SubjectInfo('irrelevant', args.subject, args.classifier)
	completion_checker = OneSubjectCompletionChecker()

	if args.output:
		processing_output = open(args.output, 'w')
	else:
		processing_output = sys.stdout

	if completion_checker.is_processing_complete(
			working_dir=args.working_dir,
			subject_info=subject_info,
			verbose=args.verbose,
			output=processing_output,
			short_circuit=not args.check_all):
		print("Exiting with 0 code - Completion Check Successful")
		exit(0)
	else:
		print("Exiting with 1 code - Completion Check Unsuccessful")
		exit(1)
