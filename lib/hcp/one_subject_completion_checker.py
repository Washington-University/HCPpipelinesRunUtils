#!/usr/bin/env python3

"""
Abstract Base Class for One Subject Completion Checker classes
"""

# import of built-in modules
import abc
import logging

# import of third-party modules

# import of local modules
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create and configure a module logger
module_logger = logging.getLogger(__file__)
module_logger.setLevel(logging.INFO)
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
module_logger.addHandler(sh)


class OneSubjectCompletionChecker(abc.ABC):
	"""
	Abstract base class for classes that are used to check the completion
	of pipeline processing for one subject
	"""

	@abc.abstractmethod
	def does_processed_resource_exist(self, archive, subject_info):
		pass

	@abc.abstractmethod
	def is_processing_complete(self, archive, subject_info, verbose):
		pass

	def do_all_files_exist(self, file_name_list, verbose=False):
		return file_utils.do_all_files_exist(file_name_list, verbose)
