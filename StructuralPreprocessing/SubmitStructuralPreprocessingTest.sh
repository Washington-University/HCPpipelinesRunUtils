#!/bin/bash

SCRIPT_NAME=$(basename "${0}")

DEFAULT_SUBJECT="HCD0102210"
DEFAULT_SESSION_CLASSIFIER="V1_MR"
DEFAULT_WORKING_DIR="/NRG-data/NRG/hcpdb/build_ssd/chpc/BUILD/${USER}/LifeSpanDevelopment"
DEFAULT_HCP_RUN_UTILS="${HOME}/pipeline_tools/HCPpipelinesRunUtils"
DEFAULT_HCP_PIPELINES_DIR="${HOME}/pipeline_tools/HCPpipelines"
DEFAULT_FSL_DIR="/export/fsl-6.0.1"
DEFAULT_FREESURFER_DIR="/export/freesurfer-6.0"
DEFAULT_WORKBENCH_DIR="/export/HCP/workbench-v1.3.2"
DEFAULT_FIELDMAP_NUMBER=1

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
	g_workbench_dir="${DEFAULT_WORKBENCH_DIR}"
	g_fieldmap_number="${DEFAULT_FIELDMAP_NUMBER}"
	
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
			--workbench-dir=*)
				g_workbench_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--fieldmap-number=*)
				g_fieldmap_number=${argument/*=/""}
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

	if [ -z " ${g_workbench_dir}" ]; then
		inform "--workbench-dir= required"
		error_count=$(( error_count + 1 ))
	else
		inform "Workbench dir: ${g_workbench_dir}"
	fi

	if [ -z " ${g_fieldmap_number}" ]; then
		inform "--fieldmap-number= required"
		error_count=$(( error_count + 1 ))
	else
		inform "Fieldmap number: ${g_fieldmap_number}"
	fi
	
	if [ ${error_count} -gt 0 ]; then
		inform "ABORTING"
		exit 1
	fi

	g_session="${g_subject}_${g_session_classifier}"

	g_run_dir="${g_hcp_run_utils}/StructuralPreprocessing" 
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
	script_file_to_submit="${g_submit_scripts_dir}/${g_session}-TestRunStructuralPreprocessing-${date_string}.sh"
	cat > ${script_file_to_submit} <<EOF
#PBS -l nodes=1:ppn=1:haswell,walltime=48:00:00,mem=32gb
#PBS -o ${g_job_logs_dir}
#PBS -e ${g_job_logs_dir}

export HCP_RUN_UTILS=${g_hcp_run_utils}
export HCPPIPEDIR=${g_hcp_pipelines_dir}
export HCPPIPEDIR_Config=${g_hcp_pipelines_dir}/global/config
export HCPPIPEDIR_Global=${g_hcp_pipelines_dir}/global/scripts
export HCPPIPEDIR_Templates=${g_hcp_pipelines_dir}/global/templates
export HCPPIPEDIR_PreFS=${g_hcp_pipelines_dir}/PreFreeSurfer/scripts
export HCPPIPEDIR_FS=${g_hcp_pipelines_dir}/FreeSurfer/scripts
export HCPPIPEDIR_PostFS=${g_hcp_pipelines_dir}/PostFreeSurfer/scripts

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

#export PATH=${g_hcp_pipelines_dir}/FreeSurfer/custom:\${PATH}
export CARET7DIR=${g_workbench_dir}/bin_rh_linux64

export MSMBINDIR=/export/HCP/MSM_HOCR_v3/Centos
export MSMCONFIGDIR=${g_hcp_pipelines_dir}/MSMConfig

echo PATH=\${PATH}
echo HCPPIPEDIR=\${HCPPIPEDIR}
echo FSLDIR=\${FSLDIR}
echo LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}

${g_run_dir}/StructuralPreprocessing.SINGULARITY_PROCESS \\
  --subject=${g_subject} \\
  --classifier=${g_session_classifier} \\
  --working-dir=${g_working_dir} \\
  --fieldmap-type=SpinEcho \\
  --first-t1w-directory-name=T1w_MPR_vNav_4e_RMS \\
  --first-t1w-file-name=${g_session}_T1w_MPR_vNav_4e_RMS.nii.gz \\
  --first-t2w-directory-name=T2w_SPC_vNav \\
  --first-t2w-file-name=${g_session}_T2w_SPC_vNav.nii.gz \\
  --brainsize=150 \\
  --t1template=MNI152_T1_0.8mm.nii.gz \\
  --t1templatebrain=MNI152_T1_0.8mm_brain.nii.gz \\
  --t1template2mm=MNI152_T1_2mm.nii.gz \\
  --t2template=MNI152_T2_0.8mm.nii.gz \\
  --t2templatebrain=MNI152_T2_0.8mm_brain.nii.gz \\
  --t2template2mm=MNI152_T2_2mm.nii.gz \\
  --templatemask=MNI152_T1_0.8mm_brain_mask.nii.gz \\
  --template2mmmask=MNI152_T1_2mm_brain_mask_dil.nii.gz \\
  --fnirtconfig=T1_2_MNI152_2mm.cnf \\
  --gdcoeffs=Prisma_3T_coeff_AS82.grad \\
  --topupconfig=b02b0.cnf \\
  --se-phase-pos=${g_session}_SpinEchoFieldMap${g_fieldmap_number}_PA.nii.gz \\
  --se-phase-neg=${g_session}_SpinEchoFieldMap${g_fieldmap_number}_AP.nii.gz \\

EOF
# --processing-phase=PreFreeSurfer
# --processing-phase=FreeSurfer
# --processing-phase=PostFreeSurfer
	
	chmod +x ${script_file_to_submit}

	submit_cmd="qsub ${script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"
	job_no=$(${submit_cmd})
	inform "job_no: ${job_no}"
}

# Invoke the main function to get things started
main $@


