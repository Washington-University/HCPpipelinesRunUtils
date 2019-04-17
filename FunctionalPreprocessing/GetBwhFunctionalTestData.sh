#!/bin/bash

pushd /HCP/hcpdb/build_ssd/chpc/BUILD/tbbrown
rsync -av --delete /HCP/hcpdb/build_ssd/chpc/BUILD/StructuralPreprocTest_BWH/1001_01_MR .
popd

