#!/bin/bash

pushd ${HOME}/pipeline_tools/HCPpipelinesRunUtils/FunctionalPreprocessing
./SubmitFunctionalPreprocessingTest.sh --study-dir=/HCP/hcpdb/build_ssd/chpc/BUILD/tbbrown --subject=1001 --session-classifier=01_MR --scan=rfMRI_REST1_AP 
popd
