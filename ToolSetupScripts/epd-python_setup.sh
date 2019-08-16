#!/bin/bash

local_log()
{
	local msg="$*"
	local date_time
	date_time=$(date)
	local tool_name="epd-python_setup.sh"
	echo "${date_time} - ${tool_name} - ${msg}"
}

EPD_PYTHON_HOME=/export/HCP/epd-7.3.2
export PATH=${EPD_PYTHON_HOME}/bin:${PATH}

# it is important that the ${EPD_PYTHON_HOME}/lib come late in the LD_LIBRARY_PATH so that the right 
# libcurl file is found by curl commands.  The libcurl that is part of this EPD_PYTHON distribution
# has https protocol disabled (as opposed to http protocol)
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${EPD_PYTHON_HOME}/lib"

unset -f local_log

