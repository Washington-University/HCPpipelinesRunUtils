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

	if (( ${error_count} > 0 )); then
		log_Err_Abort "Required parameter(s) not specified."
	fi
}

main()
{
	get_options "$@"

	local subjects=$(ls ${g_study1_dir})
	
	for subject in ${subjects} ; do

		compare_subject_cmd="${HCP_RUN_UTILS}/StructuralPreprocessing/Testing/CompareSubjectSurfaces.sh"
		compare_subject_cmd=" --study1=${g_study1_dir}"
		compare_subject_cmd=" --study2=${g_study2_dir}"
		compare_subject_cmd=" --subject=${subject}"

		if ! ${compare_subject_cmd} ; then
			log_Err_Abort "Subject surfaces are different for subject: ${subject}"
		fi
		
	done
	

	local subjects=$(ls ${g_study2_dir})

		for subject in ${subjects} ; do

		compare_subject_cmd="${HCP_RUN_UTILS}/StructuralPreprocessing/Testing/CompareSubjectSurfaces.sh"
		compare_subject_cmd=" --study1=${g_study1_dir}"
		compare_subject_cmd=" --study2=${g_study2_dir}"
		compare_subject_cmd=" --subject=${subject}"

		if ! ${compare_subject_cmd} ; then
			log_Err_Abort "Subject surfaces are different for subject: ${subject}"
		fi
		
	done
}

# Invoke the main function to get things started
main "$@"
