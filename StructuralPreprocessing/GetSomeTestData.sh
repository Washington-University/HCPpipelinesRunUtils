#!/bin/bash

# Root directory at which NRG/HCP data can be found from the CHPC
#NRG_DATA_ROOT="/HCP"
export NRG_DATA_ROOT="/NRG-data/NRG"

export XNAT_PBS_JOBS_RUN_UTILS=${HOME}/pipeline_tools/HCPpipelinesRunUtils
export XNAT_PBS_JOBS_ARCHIVE_ROOT=${NRG_DATA_ROOT}/intradb/archive
export XNAT_PBS_JOBS=${HOME}/pipeline_tools/HCPpipelinesXnatPbsJobs
export PROJECT="CCF_HCA_STG"

#pushd ${XNAT_PBS_JOBS_RUN_UTILS}/FunctionalPreprocessing

subject_list=""
subject_list+=" HCA6000030 "
subject_list+=" HCA6002236 "

session_classifier="V1_MR"
mkdir -p ${NRG_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD/${USER}/${PROJECT}

for subject in ${subject_list} ; do
	
	# clean out previous session working directory
	rm -rf ${NRG_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD/${USER}/${PROJECT}/${subject}_${session_classifier}

	# get data from database
	${XNAT_PBS_JOBS}/GetCinabStyleData/GetCinabStyleData.sh \
					--project=${PROJECT} \
					--subject=${subject} \
					--classifier=${session_classifier} \
					--study-dir=${NRG_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD/${USER}/${PROJECT} \
					--phase=struct_preproc_prereqs \
					--copy

done

