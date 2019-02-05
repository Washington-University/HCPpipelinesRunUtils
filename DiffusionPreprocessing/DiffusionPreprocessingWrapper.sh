#!/bin/bash

#
# ${HCP_RUN_UTILS}/DiffusionPreprocessing/DiffusionPreprocessingWrapper.sh
# Run the HCP Diffusion Preprocessing pipeline scripts for a specified subject data
# Copyright 2019, The Connectome Coordination Facility
#

g_pipeline_name="DiffusionPreprocessing"
g_script_name=$(basename "${0}")

if [ -z "${HCP_RUN_UTILS}" ]; then
	echo "${g_script_name}: ABORTING: HCP_RUN_UTILS environment variable must be set"
	exit 1
fi

if [ -z "${HCPPIPEDIR}" ]; then
	echo "${g_script_name}: ABORTING: HCPPIPEDIR environment variable must be set"
	exit 1
fi

# Logging related functions
source "${HCP_RUN_UTILS}/shlib/log.shlib"

# Utility functions
source "${HCP_RUN_UTILS}/shlib/utils.shlib"
log_Msg "HCP_RUN_UTILS: ${HCP_RUN_UTILS}"

# Show script usage information
usage()
{
	cat <<EOF

Run the HCP Diffusion Preprocessing pipeline scripts 

Usage: ${g_script_name} <options>

  Options: [ ] = optional, < > = user-supplied-value

  [--help] : show usage information and exit
   --subject=<subject>       : subject ID within study (e.g. 100307)
   --classifier=<classifier> : (e.g. 3T, 7T, MR, etc.)
   --working-dir=<dir>       : working directory in which to place retrieved data
                               and in which to produce results
  [--gdcoeffs=<path>]        : path to gradient coefficients file
                               defaults to NONE
  [--phase=[ALL|PREEDDY|EDDY|POSTEDDY]]
                             : PREEDDY ==> run only the Pre-Eddy phase of processing
                             : EDDY ==> run only the Eddy phase of processing 
                               (assumes that the Pre-Eddy phase has already been run)
                             : POSTEDDY ==> run only the Post-Eddy phase of processing
                               (assumes that the Pre-Eddy and Eddy phases have already 
                               been run)
                             : ALL ==> run all three phases
                               defaults to ALL
EOF
}

# Parse specified command line options and verify that required options are 
# specified. "Return" the options to use in global variables
get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_subject
	unset g_working_dir
	unset g_classifier
	unset g_gdcoeffs
	unset g_phase
	
	# set default values
	g_gdcoeffs="NONE"
	g_phase="ALL"
	
	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--help)
				usage
				exit 1
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--classifier=*)
				g_classifier=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--gdcoeffs=*)
				g_gdcoeffs=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--phase=*)
				g_phase=${argument/*=/""}
				g_phase=${g_phase^^} # uppercase
				index=$(( index + 1 ))
				;;
			*)
				usage
				log_Err_Abort "unrecognized option: ${argument}"
				;;
		esac
	done

 	local error_count=0

 	# check parameters

	if [ -z "${g_subject}" ]; then
		log_Err "subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "subject: ${g_subject}"
	fi

	if [ -z "${g_working_dir}" ]; then
		log_Err "working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "working directory: ${g_working_dir}"
	fi

	if [ -z "${g_classifier}" ]; then
		log_Err "classifier (--classifier=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "classifier: ${g_classifier}"
	fi

	if [ -z "${g_gdcoeffs}" ]; then
		log_Err "gradient distortion coefficients (--gdcoeffs=) required"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "gdcoeffs: ${g_gdcoeffs}"
	fi

	if [ -z "${g_phase}" ]; then
		log_Err "processing phase (--phase=) required"
		error_count=$(( error_count + 1 ))
	elif [ "${g_phase}" != "ALL"         \
		   -a "${g_phase}" != "PREEDDY"  \
		   -a "${g_phase}" != "EDDY"     \
		   -a "${g_phase}" != "POSTEDDY" ] ; then
		log_Err "processing phase must be one of [ALL,PREEDDY,EDDY,POSTEDDY]"
		error_count=$(( error_count + 1 ))
	else
		log_Msg "phase: ${g_phase}"
	fi
	
 	if [ ${error_count} -gt 0 ]; then
 		log_Err_Abort "For usage information, use --help"
 	fi
}

RLLR_PHASE_ENCODING_SPEC="RLLR"
PAAP_PHASE_ENCODING_SPEC="PAAP"

RLLR_POSITIVE_DIR="RL"
RLLR_NEGATIVE_DIR="LR"
PAAP_POSITIVE_DIR="PA"
PAAP_NEGATIVE_DIR="AP"

get_pe_scan_arrays()
{
	# produce arrays containing the paths to the diffusion scans of various phase encoding directions
	# input: g_working_dir, g_subject, g_classifier
	# output: g_RL_scans_array - array of paths to diffusion scans with phase encoding RL
	#         g_LR_scans_array - array of paths to diffusion scans with phase encoding LR
	#         g_PA_scans_array - array of paths to diffusion scans with phase encoding PA
	#         g_AP_scans_array - array of paths to diffusion scans with phase encoding AP
	
	local unprocessed_diffusion_data_dir="${g_working_dir}/${g_subject}/unprocessed/${g_classifier}/Diffusion"

	local RL_scans=$(find ${unprocessed_diffusion_data_dir} -maxdepth 1 -name "${g_subject}_${g_classifier}*RL.nii.gz" | sort) 
	g_RL_scans_array=(${RL_scans})

	local LR_scans=$(find ${unprocessed_diffusion_data_dir} -maxdepth 1 -name "${g_subject}_${g_classifier}*LR.nii.gz" | sort) 
	g_LR_scans_array=(${LR_scans})

	local PA_scans=$(find ${unprocessed_diffusion_data_dir} -maxdepth 1 -name "${g_subject}_${g_classifier}*PA.nii.gz" | sort) 
	g_PA_scans_array=(${PA_scans})

	local AP_scans=$(find ${unprocessed_diffusion_data_dir} -maxdepth 1 -name "${g_subject}_${g_classifier}*AP.nii.gz" | sort) 
	g_AP_scans_array=(${AP_scans})
}


get_phase_encoding_spec()
{
	# input: g_RL_scans_array, g_LR_scans_array, g_PA_scans_array, g_AP_scans_array - as output from get_pe_scans_arrays
	# output: g_phase_encoding_spec - indication of whether the phase encoding pairs for the diffusion scans are RLLR or PAAP

	# Figure out whether PAAP or RLLR phase encoding is used
	local num_RL_scans=${#g_RL_scans_array[@]}
	local num_LR_scans=${#g_LR_scans_array[@]}
	local num_PA_scans=${#g_PA_scans_array[@]}
	local num_AP_scans=${#g_AP_scans_array[@]}

	g_phase_encoding_spec=""
	if (( num_RL_scans > 0 )) && (( num_LR_scans > 0 )) && (( num_PA_scans = 0 )) && (( num_AP_scans = 0 )) ; then
		g_phase_encoding_spec="${RLLR_PHASE_ENCODING_SPEC}"
		log_Msg "Determined phase_encoding_dir: ${g_phase_encoding_spec}"
	elif (( num_PA_scans > 0 )) && (( num_AP_scans > 0 )) ; then
		g_phase_encoding_spec="${PAAP_PHASE_ENCODING_SPEC}"
		log_Msg "Determined phase_encoding_dir: ${g_phase_encoding_spec}"
	else
		log_Err "num_RL_scans: ${num_RL_scans}"
		log_Err "num_LR_scans: ${num_LR_scans}"
		log_Err "num_PA_scans: ${num_PA_scans}"
		log_Err "num_AP_scans: ${num_AP_scans}"
		log_Err_Abort "Unable to determine phase encoding direction to use"
	fi
}

get_data_file_lists()
{
	# input: g_RL_scans_array, g_LR_scans_array, g_PA_scans_array, g_AP_scans_array - as output from get_pe_scans_arrays
	#        g_phase_encoding_spec - as output from get_phase_encoding_spec
	# output: g_pos_data - list of positive PE scans formatted for input as the --posData= argument for the PreEddy Script
	#         g_neg_data - list of negative PE scans formatted for input as the --negData= argument for the PreEddy Script

	g_pos_data=""
	g_neg_data=""
	
	if [[ "${g_phase_encoding_spec}" = "${RLLR_PHASE_ENCODING_SPEC}" ]]; then

		# RL is the POSITIVE direction
		
		for file_spec in "${g_RL_scans_array[@]}" ; do
			if [ ! -z "${g_pos_data}" ] ; then
				# g_pos_data is not empty, so add an "@" before adding a file spec
				g_pos_data+="@"
			fi
			g_pos_data+="${file_spec}"
		done

		# LR is the NEGATIVE direction
		
		for file_spec in "${g_LR_scans_array[@]}" ; do
			if [ ! -z "${g_neg_data}" ] ; then
				# g_neg_data is not empty, so add and "@" before adding a file spec
				g_neg_data+="@"
			fi
			g_neg_data+="${file_spec}"
		done
		
	elif [[ "${g_phase_encoding_spec}" = "${PAAP_PHASE_ENCODING_SPEC}" ]]; then

		# PA is the POSITIVE direction
		
		for file_spec in "${g_PA_scans_array[@]}" ; do
			if [ ! -z "${g_pos_data}" ] ; then
				# g_pos_data is not empty, so add an "@" before adding a file spec
				g_pos_data+="@"
			fi
			g_pos_data+="${file_spec}"
		done

		# AP is the NEGATIVE direction

		for file_spec in "${g_AP_scans_array[@]}" ; do
			if [ ! -z "${g_neg_data}" ] ; then
				# g_neg_data is not empty, so add and "@" before adding a file spec
				g_neg_data+="@"
			fi
			g_neg_data+="${file_spec}"
		done
		
	else
		log_Err_Abort "Unrecognized value for g_phase_encoding_spec = ${g_phase_encoding_spec}"
	fi
}

get_effective_echo_spacing_msecs()
{
	# input: g_RL_scans_array, g_LR_scans_array, g_PA_scans_array, g_AP_scans_array - as output from get_pe_scans_arrays
	#        g_phase_encoding_spec - as output from get_phase_encoding_spec
	# output: g_effective_echo_spacing_msecs - effective echo spacing (msecs) for diffusion scans


	local effective_echo_spacing_secs=""
	local val
	
	if [[ "${g_phase_encoding_spec}" = "${RLLR_PHASE_ENCODING_SPEC}" ]]; then		

		for file_spec in "${g_LR_scans_array[@]}" "${g_RL_scans_array[@]}" ; do
			val=$(${HCP_RUN_UTILS}/lib/utils/get_json_meta_data.sh -f ${file_spec} -k EffectiveEchoSpacing)
			if [ -z "${effective_echo_spacing_secs}" ] ; then
				effective_echo_spacing_secs="${val}"
			elif [ "${effective_echo_spacing_secs}" != "${val}" ] ; then
				log_Err_Abort "Multiple different effective echo spacing values found: ${effective_echo_spacing_secs} and ${val}"
			fi
		done

	elif [[ "${g_phase_encoding_spec}" = "${PAAP_PHASE_ENCODING_SPEC}" ]]; then

		for file_spec in "${g_PA_scans_array[@]}" "${g_AP_scans_array[@]}" ; do
			val=$(${HCP_RUN_UTILS}/lib/utils/get_json_meta_data.sh -f ${file_spec} -k EffectiveEchoSpacing)			
			if [ -z "${effective_echo_spacing_secs}" ] ; then
				effective_echo_spacing_secs="${val}"
			elif [ "${effective_echo_spacing_secs}" != "${val}" ] ; then
				log_Err_Abort "Multiple different effective echo spacing values found: ${effective_echo_spacing_secs} and ${val}"
			fi
		done

	else
		log_Err_Abort "Unrecognized value for g_phase_encoding_spec = ${g_phase_encoding_spec}"
	fi

	g_effective_echo_spacing_msecs=$(echo "${effective_echo_spacing_secs} 1000.0" | awk '{printf "%.12f", $1 * $2}')

	log_Msg "effective_echo_spacing_secs: ${effective_echo_spacing_secs}"
	log_Msg "g_effective_echo_spacing_msecs: ${g_effective_echo_spacing_msecs}"
}

# Main processing
main()
{
	local PreEddy_cmd
	local Eddy_cmd
	local PostEddy_cmd
	local ret_code

	# --------------------
	
	log_Debug_On

	show_job_start

	show_platform_info
	
	get_options "$@"

	log_execution_info ${g_working_dir} "${g_script_name}" ${g_subject} ${g_classifier}

	create_start_time_file ${g_working_dir} ${g_pipeline_name} ${g_subject} ${g_classifier}

	# get diffusion scan paths segregated into phase encoding directions
	get_pe_scan_arrays

	# determine the phase encoding pairs
	get_phase_encoding_spec

	# Build positive and negative data file parameters
	get_data_file_lists

	# Get the echo spacing (in msecs)
	get_effective_echo_spacing_msecs

	# Build and execute Pre-eddy command
	if [ "${g_phase}" = "PREEDDY" -o "${g_phase}" = "ALL" ]; then
		PreEddy_cmd=""
		PreEddy_cmd+="${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_PreEddy.sh"
		PreEddy_cmd+=" --path=${g_working_dir}"
		PreEddy_cmd+=" --subject=${g_subject}"

		if [[ "${g_phase_encoding_spec}" = "${RLLR_PHASE_ENCODING_SPEC}" ]]; then
			PreEddy_cmd+=" --PEdir=1"
		elif [ "${g_phase_encoding_spec}" = "${PAAP_PHASE_ENCODING_SPEC}" ] ; then
			PreEddy_cmd+=" --PEdir=2"
		else
			log_Err_Abort "Unrecognized phase encoding direction specifier: ${g_phase_encoding_spec}"
		fi

		PreEddy_cmd+=" --posData=${g_pos_data}"
		PreEddy_cmd+=" --negData=${g_neg_data}"
		PreEddy_cmd+=" --echospacing=${g_effective_echo_spacing_msecs}"
		
		log_Msg ""
		log_Msg "PreEddy_cmd: ${PreEddy_cmd}"
		log_Msg ""
		
		${PreEddy_cmd}
		ret_code=$?
		
		if [ "${ret_code}" -ne 0 ] ; then
			log_Err_Abort "PreEddy_cmd failed with return code: ${ret_code}"
		fi
	fi
	
	# Build and execute Eddy command
	if [ "${g_phase}" = "EDDY" -o "${g_phase}" = "ALL" ]; then
		Eddy_cmd=""
		Eddy_cmd+="${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_Eddy.sh"
		Eddy_cmd+=" --path=${g_working_dir}"
		Eddy_cmd+=" --subject=${g_subject}"
		Eddy_cmd+=" --detailed-outlier-stats=True"
		Eddy_cmd+=" --replace-outliers=True"
		Eddy_cmd+=" --nvoxhp=2000"
		Eddy_cmd+=" --sep_offs_move=True"
		Eddy_cmd+=" --rms=True"
		Eddy_cmd+=" --ff=10"
		Eddy_cmd+=" --dont_peas"
		Eddy_cmd+=" --fwhm=10,0,0,0,0"
		Eddy_cmd+=" --ol_nstd=5"
		Eddy_cmd+=" --extra-eddy-arg=--with_outliers"
		Eddy_cmd+=" --extra-eddy-arg=--initrand"
		Eddy_cmd+=" --extra-eddy-arg=--very_verbose"
		
		log_Msg ""
		log_Msg "Eddy_cmd: ${Eddy_cmd}"
		log_Msg ""
		
		${Eddy_cmd}
		ret_code=$?
	
		if [ "${ret_code}" -ne 0 ] ; then
			log_Err_Abort "Eddy_cmd failed with return code: ${ret_code}"
		fi
	fi
	
	# Build and execute Post-eddy command
	if [ "${g_phase}" = "POSTEDDY" -o "${g_phase}" = "ALL" ]; then
		PostEddy_cmd=""
		PostEddy_cmd+="${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_PostEddy.sh"
		PostEddy_cmd+=" --path=${g_working_dir}"
		PostEddy_cmd+=" --subject=${g_subject}"
		PostEddy_cmd+=" --gdcoeffs=${g_gdcoeffs}"
		
		log_Msg ""
		log_Msg "PostEddy_cmd: ${PostEddy_cmd}"
		log_Msg ""
		
		${PostEddy_cmd}
		ret_code=$?
		
		if [ "${ret_code}" -ne 0 ] ; then
			log_Err_Abort "PostEddy_cmd failed with return code: ${ret_code}"
		fi
	fi
	
	log_Msg "Complete"
}

# Invoke the main function to get things started
main "$@"
