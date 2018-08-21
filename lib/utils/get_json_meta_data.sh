#!/bin/bash

if [ -z "${HCP_RUN_UTILS}" ]; then
	script_name=$(basename "${0}")
	echo "${script_name}: ABORTING: HCP_RUN_UTILS environment variable must be set"
	exit 1
fi

source ${HCP_RUN_UTILS}/shlib/utils.shlib
set_g_python_environment
source activate ${g_python_environment} 2>/dev/null
${HCP_RUN_UTILS}/lib/utils/get_json_meta_data.py $@
source deactivate 2>/dev/null
