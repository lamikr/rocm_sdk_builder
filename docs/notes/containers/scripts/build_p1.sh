cp -f docs/notes/docker/config/build_cfg_rdna3.user build_cfg.user
./babs.sh -b docs/notes/docker/blist/binfo_core_p1.blist

#if [ -d builddir/003_llvm_project_llvm ]; then
#    cd builddir/003_llvm_project_llvm
#    rm -rf *
#fi
#if [ -d ../023_04_SuiteSparse ]; then
#    cd ../023_04_SuiteSparse
#    rm -rf *
#fi
#if [ -d ../025_02_hipBLASLt ]; then
#    cd ../025_02_hipBLASLt
#    rm -rf *
#fi
#if [ -d ../028_02_hipSPARSELt ]; then
#    cd ../028_02_hipSPARSELt
#    rm -rf *
#fi
#if [ -d ../031_01_miopen_rocMLIR ]; then
#    cd ../031_01_miopen_rocMLIR
#    rm -rf *
#fi
#if [ -d ../033_01_composable_kernel ]; then
#    cd ../033_01_composable_kernel
#    rm -rf *
#fi
