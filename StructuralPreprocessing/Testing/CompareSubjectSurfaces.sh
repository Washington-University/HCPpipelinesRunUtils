#!/bin/bash

g_script_name=$(basename "${0}")

if [ -z "${HCP_RUN_UTILS}" ]; then
	echo "${g_script_name}: ABORTING: HCP_RUN_UTILS environment variable must be set"
	exit 1
fi

source "${HCP_RUN_UTILS}/shlib/log.shlib"	# Logging related functions

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_study1_dir
	unset g_study2_dir
	unset g_subject

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while (( index < num_args )) ; do
		argument=${arguments[index]}

		case ${argument} in
			--study1=*) # e.g. /study/FreeSurfer6_v5/HCPYA
				g_study1_dir=${argument#*=}
				index=$(( index + 1 ))
				;;
			--study2=*) # e.g. /study/FreeSurfer6_v6/HCPYA
				g_study2_dir=${argument#*=}
				index=$(( index + 1 ))
				;;
			--subject=*) # e.g. 100307
				g_subject=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				log_Err_Abort "unrecognized option: ${argument}"
				;;
		esac
		
	done

	local error_count=0

	# check required parameters

	if [ -z "${g_study1_dir}" ]; then
		log_Err "study1 (--study1=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "study1: ${g_study1_dir}"
	fi

	if [ -z "${g_study2_dir}" ]; then
		log_Err "study2 (--study2=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "study2: ${g_study2_dir}"
	fi

	
	if [ -z "${g_subject}" ]; then
		log_Err "subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "subject: ${g_subject}"
	fi

	if (( ${error_count} > 0 )); then
		log_Err_Abort "Required parameter(s) not specified."
	fi
}


main()
{
	get_options "$@"

	local freesurfer_study1_dir="${g_study1_dir}/${g_subject}/T1w"
	local freesurfer_study2_dir="${g_study2_dir}/${g_subject}/T1w"


	for surface in pial white thickness; do
		for hemisphere in rh lh ; do
			mris_diff_cmd="mris_diff"
			mris_diff_cmd+=" --sd1 ${freesurfer_study1_dir}"
			mris_diff_cmd+=" --s1  ${g_subject}"
			mris_diff_cmd+=" --sd2 ${freesurfer_study2_dir}"
			mris_diff_cmd+=" --s2  ${g_subject}"
			mris_diff_cmd+=" --hemi ${hemisphere}"
			mris_diff_cmd+=" --surf ${surface}"

			if ! ${mris_diff_cmd} ; then
				log_Err_Abort "Surfaces are different"
			fi
		done # hemisphere
	done # surface
}

# Invoke the main function to get things started
main "$@"
