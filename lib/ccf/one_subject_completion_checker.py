#!/usr/bin/env python3

"""
Abstract Base Class for One Subject Completion Checker Classes
"""

# import of built-in modules
import abc
import os
import sys

# import of third-party modules

# import of local modules
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

class OneSubjectCompletionChecker(abc.ABC):
	"""
	Abstract base class for classes that are used to check the completion
	of pipeline processing for one subject
	"""

	@abc.abstractmethod
	def list_of_expected_files(self, working_dir, subject_info):
		pass
				
	def do_all_files_exist(self, file_name_list, verbose=False, output=sys.stdout, short_circuit=True):
		return file_utils.do_all_files_exist(file_name_list, verbose, output, short_circuit)
	
	def is_processing_complete(self, working_dir, subject_info,
							   verbose=False, output=sys.stdout, short_circuit=True):
		expected_file_list = self.list_of_expected_files(working_dir, subject_info)
		return self.do_all_files_exist(expected_file_list, verbose, output, short_circuit)
