#!/bin/bash

# Root directory at which NRG/HCP data can be found from the CHPC
#NRG_DATA_ROOT="/HCP"
export NRG_DATA_ROOT="/NRG-data/NRG"

export XNAT_PBS_JOBS_RUN_UTILS=${HOME}/pipeline_tools/HCPpipelinesRunUtils
export XNAT_PBS_JOBS_ARCHIVE_ROOT=${NRG_DATA_ROOT}/intradb/archive
export XNAT_PBS_JOBS=${HOME}/pipeline_tools/HCPpipelinesXnatPbsJobs

pushd ${XNAT_PBS_JOBS_RUN_UTILS}/FunctionalPreprocessing

subject_list=""
subject_list+=" 1001 "
subject_list+=" 1002 "
subject_list+=" 1003 "
subject_list+=" 1004 "
subject_list+=" 1006 "

for subject in ${subject_list} ; do
	
	# clean out previous session working directory
	rm -rf ${NRG_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD/${USER}/BWH/${subject}_01_MR

	# get data from database
	${XNAT_PBS_JOBS}/GetCinabStyleData/GetCinabStyleData.sh \
					--project=CCF_BWH_STG \
					--subject=${subject} \
					--classifier=01_MR \
					--study-dir=${NRG_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD/${USER}/BWH \
					--phase=func_preproc_prereqs \
					--copy

	# Submit a test run
	./SubmitFunctionalPreprocessingTest.sh \
		--study-dir=${NRG_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD/${USER}/BWH \
		--subject=${subject} \
		--session-classifier=01_MR \
		--scan=rfMRI_REST1_AP  

	echo ""

done

popd
