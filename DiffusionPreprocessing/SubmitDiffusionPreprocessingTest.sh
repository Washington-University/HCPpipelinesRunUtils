#!/bin/bash

SCRIPT_NAME="SubmitDiffusionPreprocessingTest.sh"
HCP_RUN_UTILS="/home/tbbrown/pipeline_tools/HCPpipelinesRunUtils"
HCPPIPEDIR="/home/tbbrown/pipeline_tools/HCPpipelines"
RUN_DIR="${HCP_RUN_UTILS}/DiffusionPreprocessing"
SUBJECT="HCA6002236"
WORKING_DIR="/home/tbbrown/data/LifeSpanAging"
INTERACTIVE="FALSE"
#SUBMIT_SCRIPTS_DIR=${HOME}/submit_scripts
#JOB_LOGS_DIR=${HOME}/joblogs
SUBMIT_SCRIPTS_DIR="${WORKING_DIR}/${SUBJECT}/ProcessingInfo"
JOB_LOGS_DIR="${WORKING_DIR}/${SUBJECT}/ProcessingInfo"

inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

main()
{
	local script_file_to_submit
	local submit_cmd
	local job_no
	local date_string
 
	mkdir -p ${SUBMIT_SCRIPTS_DIR}
	date_string=$(date +%s)
	script_file_to_submit="${SUBMIT_SCRIPTS_DIR}/TestRunDiffusionPreprocessing-${SUBJECT}-${date_string}.sh"
	cat > ${script_file_to_submit} <<EOF
#PBS -l nodes=1:ppn=3:gpus=1,walltime=24:00:00
#PBS -o ${JOB_LOGS_DIR}
#PBS -e ${JOB_LOGS_DIR}

export HCP_RUN_UTILS=${HCP_RUN_UTILS}
export HCPPIPEDIR=${HCPPIPEDIR}
export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config
export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
export FSLDIR=/export/fsl-6.0.0_OpenBLAS
source \${FSLDIR}/etc/fslconf/fsl.sh
export PATH=\${FSLDIR}/bin:\${PATH}

export EPD_PYTHON_HOME=/export/HCP/epd-7.3.2
export PATH=\${EPD_PYTHON_HOME}/bin:\${PATH}

# it is important that the ${EPD_PYTHON_HOME}/lib come late in the LD_LIBRARY_PATH so that the right
# libcurl file is found by curl commands.  The libcurl that is part of this EPD_PYTHON distribution
# has https protocol disabled (as opposed to http protocol)
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${EPD_PYTHON_HOME}/lib

module load cuda-7.5
module load gcc-4.7.2
export LD_LIBRARY_PATH=\${FSLDIR}/lib:\${LD_LIBRARY_PATH}

echo PATH=\${PATH}
echo HCPPIPEDIR=\${HCPPIPEDIR}
echo FSLDIR=\${FSLDIR}
echo LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}

${RUN_DIR}/DiffusionPreprocessingWrapper.sh \\
  --working-dir=${WORKING_DIR} \\
  --subject=${SUBJECT} \\
  --classifier=V1_MR \\
  --gdcoeffs=${HCPPIPEDIR_Config}/Prisma_3T_coeff_AS82.grad \\
  --phase=POSTEDDY
EOF
	
	chmod +x ${script_file_to_submit}

	if [ "${INTERACTIVE}" = "TRUE" ]; then
		submit_cmd="${script_file_to_submit}"
		inform "submit_cmd: ${submit_cmd}"
		${submit_cmd} > ${script_file_to_submit}.stdout 2> ${script_file_to_submit}.stderr
	else
		submit_cmd="qsub ${script_file_to_submit}"
		inform "submit_cmd: ${submit_cmd}"
		job_no=$(${submit_cmd})
		inform "job_no: ${job_no}"
	fi
}

# Invoke the main function to get things started
main $@
