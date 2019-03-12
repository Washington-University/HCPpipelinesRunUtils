#!/bin/bash

SCRIPT_NAME=$(basename "${0}")

DEFAULT_DIRECTORY=""
DEFAULT_AFTER_JOB_NUMBER=""

inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

get_options()
{
	local arguments=($@)

	# initialize global output variables

	# set default values
	g_directory="${DEFAULT_DIRECTORY}"
	g_after_job_number="${DEFAULT_AFTER_JOB_NUMBER}"
	
	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--directory=*)
				g_directory=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--dir=*)
				g_directory=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--after-job-number=*)
				g_after_job_number=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				inform "Unrecognized option: ${argument}"
				exit 1
				;;
		esac

	done

	local error_count=0

	# check parameters

	if [ -z "${g_directory}" ]; then
		inform "--directory= or --dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "directory: ${g_directory}"
	fi

	if [ ! -z "${g_after_job_number}" ]; then
		inform "After Job Number: ${g_after_job_number}"
	fi
	
	if [ ${error_count} -gt 0 ]; then
		inform "ABORTING"
		exit 1
	fi

	g_job_logs_dir=${HOME}/joblogs
}

main()
{
	get_options "$@"

	local script_file_to_submit
	local submit_cmd
	local job_no
	local date_string
	
	date_string=$(date +%s)
	script_file_to_submit="${HOME}/submit_scripts/OpenPermissions-${date_string}.sh"
	cat > ${script_file_to_submit} <<EOF
#PBS -o ${g_job_logs_dir}
#PBS -e ${g_job_logs_dir}

chmod --recursive --verbose 777 ${g_directory}

EOF

	chmod +x ${script_file_to_submit}

	submit_cmd="qsub"
	if [ ! -z "${g_after_job_number}" ]; then
		submit_cmd+=" -W depend=afterany:${g_after_job_number}"
	fi
	submit_cmd+=" ${script_file_to_submit}"
	job_no=$(${submit_cmd})
	inform "job_no: ${job_no}"
}

# Invoke the main function to get things started
main $@

