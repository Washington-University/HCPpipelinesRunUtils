#!/bin/bash

SCRIPT_NAME=$(basename "${0}")

DEFAULT_SUBJECT="HCA6002236"
DEFAULT_SESSION_CLASSIFIER="V1_MR"
DEFAULT_WORKING_DIR="/HCP/hcpdb/build_ssd/chpc/BUILD/${USER}/LifeSpanAging"
DEFAULT_HCP_RUN_UTILS="${HOME}/pipeline_tools/HCPpipelinesRunUtils"
DEFAULT_HCP_PIPELINES_DIR="${HOME}/pipeline_tools/HCPpipelines"
DEFAULT_FSL_DIR="/export/HCP/fsl-6.0.1b0"
DEFAULT_FREESURFER_DIR="/export/freesurfer-6.0"
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
	g_hcp_run_utils="${DEFAULT_HCP_RUN_UTILS}"
	g_hcp_pipelines_dir="${DEFAULT_HCP_PIPELINES_DIR}"
	g_subject="${DEFAULT_SUBJECT}"
	g_session_classifier="${DEFAULT_SESSION_CLASSIFIER}"
	g_working_dir="${DEFAULT_WORKING_DIR}"
	g_fsl_dir="${DEFAULT_FSL_DIR}"
	g_freesurfer_dir="${DEFAULT_FREESURFER_DIR}"
	g_after_job_number="${DEFAULT_AFTER_JOB_NUMBER}"
	
	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--hcp-run-utils=*)
				g_hcp_run_utils=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--hcp-pipelines-dir=*)
				g_hcp_pipelines_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--session-classifier=*)
				g_session_classifier=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--study-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--fsl-dir=*)
				g_fsl_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--freesurfer-dir=*)
				g_freesurfer_dir=${argument/*=/""}
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

	if [ -z "${g_hcp_run_utils}" ]; then
		inform "--hcp-run-utils= required"
		error_count=$(( error_count + 1 ))
	else
		inform "HCP pipeline run utilities: ${g_hcp_run_utils}"
	fi

	if [ -z "${g_hcp_pipelines_dir}" ]; then
		inform "--hcp-pipelines-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "HCP pipelines: ${g_hcp_pipelines_dir}"
	fi
	
	if [ -z "${g_subject}" ]; then
		inform "--subject= required"
		error_count=$(( error_count + 1 ))
	else
		inform "subject: ${g_subject}"
	fi

	if [ -z "${g_session_classifier}" ]; then
		inform "--session-classifier= required"
		error_count=$(( error_count + 1 ))
	else
		inform "session classifier: ${g_session_classifier}"
	fi
	
	if [ -z "${g_working_dir}" ]; then
		inform "--working-dir= or --study-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "working/study dir: ${g_working_dir}"
	fi
	
	if [ -z "${g_fsl_dir}" ]; then
		inform "--fsl-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "FSL dir: ${g_fsl_dir}"
	fi

	if [ -z "${g_freesurfer_dir}" ]; then
		inform "--freesurfer-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "FreeSurfer dir: ${g_freesurfer_dir}"
	fi
	
	if [ ! -z "${g_after_job_number}" ]; then
		inform "After Job Number: ${g_after_job_number}"
	fi
	
	if [ ${error_count} -gt 0 ]; then
		inform "ABORTING"
		exit 1
	fi

	g_session="${g_subject}_${g_session_classifier}"

	g_run_dir="${g_hcp_run_utils}/DiffusionPreprocessing" 
	g_submit_scripts_dir="${g_working_dir}/${g_session}/ProcessingInfo"
	g_job_logs_dir="${g_working_dir}/${g_session}/ProcessingInfo"
}

main()
{
	get_options "$@"

	local script_file_to_submit
	local submit_cmd
	local job_no
	local date_string
 
	mkdir -p ${g_submit_scripts_dir}
	date_string=$(date +%s)
	script_file_to_submit="${g_submit_scripts_dir}/${g_session}-TestRunDiffusionPreprocessing-${date_string}.sh"
	cat > ${script_file_to_submit} <<EOF
#PBS -l nodes=1:ppn=3:gpus=1,walltime=24:00:00
#PBS -o ${g_job_logs_dir}
#PBS -e ${g_job_logs_dir}

module load cuda-8.0
module load gcc-4.7.2

export HCP_RUN_UTILS=${g_hcp_run_utils}
export HCPPIPEDIR=${g_hcp_pipelines_dir}
export HCPPIPEDIR_dMRI=${g_hcp_pipelines_dir}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_Config=${g_hcp_pipelines_dir}/global/config
export HCPPIPEDIR_Global=${g_hcp_pipelines_dir}/global/scripts
export FSLDIR=${g_fsl_dir}
source \${FSLDIR}/etc/fslconf/fsl.sh
export PATH=\${FSLDIR}/bin:\${PATH}

export FREESURFER_HOME=${g_freesurfer_dir}
source \${FREESURFER_HOME}/SetUpFreeSurfer.sh

export EPD_PYTHON_HOME=/export/HCP/epd-7.3.2
export PATH=\${EPD_PYTHON_HOME}/bin:\${PATH}

# it is important that the ${EPD_PYTHON_HOME}/lib come late in the LD_LIBRARY_PATH so that the right
# libcurl file is found by curl commands.  The libcurl that is part of this EPD_PYTHON distribution
# has https protocol disabled (as opposed to http protocol)
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${EPD_PYTHON_HOME}/lib

export LD_LIBRARY_PATH=\${FSLDIR}/lib:\${LD_LIBRARY_PATH}

echo PATH=\${PATH}
echo HCPPIPEDIR=\${HCPPIPEDIR}
echo FSLDIR=\${FSLDIR}
echo LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}

${g_run_dir}/DiffusionPreprocessingWrapper.sh \\
  --working-dir=${g_working_dir} \\
  --subject=${g_subject} \\
  --classifier=${g_session_classifier} \\
  --gdcoeffs=\${HCPPIPEDIR_Config}/Prisma_3T_coeff_AS82.grad \\

EOF
#  --phase=PREEDDY
#  --phase=EDDY
#  --phase=POSTEDDY
	
	chmod +x ${script_file_to_submit}

	submit_cmd="qsub"
	if [ ! -z "${g_after_job_number}" ]; then
		submit_cmd+=" -W depend=afterok:${g_after_job_number}"
	fi
	submit_cmd+=" ${script_file_to_submit}"

	inform "submit_cmd: ${submit_cmd}"
	job_no=$(${submit_cmd})
	inform "job_no: ${job_no}"
}

# Invoke the main function to get things started
main $@
