#!/bin/bash

func_patch_env_init() {
	if [ -z ${SDK_ROOT_DIR} ]; then
		echo "initializing build environment variables"
		source ./binfo/envsetup.sh
	fi
	if [ -z ${SDK_ROOT_DIR} ]; then
		echo "build env init failed, SDK_ROOT_DIR: " ${SDK_ROOT_DIR}
		exit 1
	else
		echo "SDK_ROOT_DIR: " $SDK_ROOT_DIR
	fi
}

func_patch_repo_init() {
	cd ${SDK_ROOT_DIR}/ROCT-Thunk-Interface
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout ea01eb30ea825a0a0d7a9c9b7c665dc1ee5565bd

	cd ${SDK_ROOT_DIR}/ROCR-Runtime
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout ae653deee7c15ca1ef81d1f18204d533d65c8ccb

	cd ${SDK_ROOT_DIR}/hcc/llvm-project
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout 561ee2bf26580babbce1e512537315bc8d4446e0

	cd ${SDK_ROOT_DIR}/hcc/rocdl
	pwd
	git roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout b9c3a2726446ffde1c9280806052c09d67dc736f

	cd ${SDK_ROOT_DIR}/hcc
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout fdd9fde48eaa8a0d648544cd717ca40d5841671c
	
	cd ${SDK_ROOT_DIR}/llvm_amd-stg-open
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	# latest from branch amd-stg-open
	git checkout 9b1801e794460eacb7bff0d3793d627180246c10

	cd ${SDK_ROOT_DIR}/ROCm-Device-Libs
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout c214a58482cab30fd3cdf9cc6fda5bd432aa2f9e

	cd ${SDK_ROOT_DIR}/ROCm-CompilerSupport
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout c5546b4ba2b5b75a4e88b1d0f402d06fea3fa4db

	cd ${SDK_ROOT_DIR}/aomp/hip
	pwd
	git fetch rocm-devtools
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout d29ad504640ddf608368c0a97de5ef28a18b5fa0

	cd ${SDK_ROOT_DIR}/rocm-cmake
	pwd
	git fetch roc-github
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout ac2b6c1b9e94cdee419026c82938e12eb4bc8419

	cd ${SDK_ROOT_DIR}/rccl
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest from master
	git checkout 0976e47b066e489390a847b22edb55efd8120af7

	cd ${SDK_ROOT_DIR}/rocRAND
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest from develop branch
	git checkout f5b2aa6805c83b883e764b97a993ef8e0bda888c

	cd ${SDK_ROOT_DIR}/rocFFT
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout e732369e58fcdbf3c5235ea6f12bf4928011fb09

	cd ${SDK_ROOT_DIR}/rocPRIM
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout 6042e8aa752e971ab8c63d90b9b4df93fcad36e4

	cd ${SDK_ROOT_DIR}/rocSPARSE
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest from develop branch
	git checkout 593d8773a5a7cc1eb81717d3ccbcf523f0047e4d

	cd ${SDK_ROOT_DIR}/rocBLAS
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout 6fbe088a5341f57e287ff3978384cf5a973bc285

	cd ${SDK_ROOT_DIR}/Tensile
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout fdd9ef8d5a0687596efee85b7ec187f1fb097087

	cd ${SDK_ROOT_DIR}/rocALUTION
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout rocm-swplat/master

	cd ${SDK_ROOT_DIR}/rocm_smi_lib
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest master
	git checkout aabe26ab0c9f9891e88e22c04a6b924e9e181611

	cd ${SDK_ROOT_DIR}/ROC-smi
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest master
	git checkout 840011e9e22f8b627584de677e325bc66307509e

	cd ${SDK_ROOT_DIR}/hipCUB
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#develop branch	
	git checkout 61fca3eb1862cd38b4c0a6d5bfff0f860d46d670

	cd ${SDK_ROOT_DIR}/hipSPARSE
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest from develop branch
	git checkout rocm-swplat/master

	cd ${SDK_ROOT_DIR}/clang-ocl
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest from master branch, not updated often
	git checkout roc-3.1.0

	cd ${SDK_ROOT_DIR}/MIOpen
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	#latest on master branch
	git checkout 2fe2ae900feda7940144d2c56557707f2c3d81ee
	
	cd ${SDK_ROOT_DIR}/MIOpenGEMM
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout rocm-swplat/master

	cd ${SDK_ROOT_DIR}/tensorflow_r11_hip_hcc
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout 29b7532cd8da9ba515f60263a7c2c7841994764d

	cd ${SDK_ROOT_DIR}/tensorflow_r21_hip_hcc
	pwd
	git fetch --all
	#git am --abort
	#git reset --hard
	git checkout 5466af3d12cda554b5788341ac5df745ad897464
}

func_patch_apply() {
	cd ${SDK_ROOT_DIR}/ROCR-Runtime
	pwd
	#git am ${PATCH_FILE_ROOT_DIR}/rocr-runtime/debug/0001-amd-2400g-vega11-raven-ridge-cfx902-rocr-rt-wt-dbg.patch
	#git am ${PATCH_FILE_ROOT_DIR}/rocr-runtime/debug/0002-navi-rx5700-cfx1010-support.patch
	git am ${PATCH_FILE_ROOT_DIR}/rocr-runtime/release/0*.patch

	cd ${SDK_ROOT_DIR}/hcc/llvm-project
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/hcc_llvm-project/release/00*.patch

	cd ${SDK_ROOT_DIR}/hcc
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/hcc/hcc/release/0*.patch
	
	#cd cd ${SDK_ROOT_DIR}/llvm_amd-stg-open
	#git am ${PATCH_FILE_ROOT_DIR}/hcc/hcc/release/0001-amd-2400g-vega11-raven-ridge-cfx902-hcc-support.patch

	cd ${SDK_ROOT_DIR}/aomp/hip
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/hip/release/0*
	#git am ${PATCH_FILE_ROOT_DIR}/hip/hip/debug/0001-updated-gitignore.patch

	cd ${SDK_ROOT_DIR}/rccl
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/rccl/release/0*.patch

	cd ${SDK_ROOT_DIR}/rocRAND
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/rocRAND/release/0*.patch

	cd ${SDK_ROOT_DIR}/rocFFT
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/rocFFT/release/0*.patch

	cd ${SDK_ROOT_DIR}/rocPRIM
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/rocPRIM/release/0*.patch

	cd ${SDK_ROOT_DIR}/rocSPARSE
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/rocSPARSE/release/0*.patch

	cd ${SDK_ROOT_DIR}/ROC-smi
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/ROC-smi/release//0*.patch

	cd ${SDK_ROOT_DIR}/hipCUB
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/hipCUB/release/0*.patch

	cd ${SDK_ROOT_DIR}/rocBLAS
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/rocBLAS/release/0*
	
	cd ${SDK_ROOT_DIR}/hipSPARSE
	pwd

	cd ${SDK_ROOT_DIR}/Tensile
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/Tensile/release/0*.patch
	
	cd ${SDK_ROOT_DIR}/MIOpen
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/MIOpen/release/0*.patch
	
	cd ${SDK_ROOT_DIR}/MIOpenGEMM
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/MIOpenGEMM/release/0*.patch

	cd ${SDK_ROOT_DIR}/rocALUTION
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/rocALUTION/release/0*.patch

	cd ${SDK_ROOT_DIR}/tensorflow_r11_hip_hcc
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/tensorflow_r11_hip_hcc/release/0*.patch

	cd ${SDK_ROOT_DIR}/tensorflow_r21_hip_hcc
	pwd
	git am ${PATCH_FILE_ROOT_DIR}/tensorflow_r21_hip_hcc/release/0*.patch
}

func_patch_env_init
func_patch_repo_init
func_patch_apply
