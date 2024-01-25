LIST_BINFO_FILE_BASENAME=(
    "001_rocm_core.binfo"
    "002_python.binfo"
    "003_llvm_project_llvm.binfo"
    "004_01_roct-thunk-interface_shared.binfo"
    "004_02_roct-thunk-interface_static.binfo"
    "005_rocm-cmake.binfo"
    "006_hip_clang_rocm-device-libs.binfo"
    "007_01_rocr-runtime.binfo"
    "007_02_rocminfo.binfo"
    "008_rocm-compilersupport.binfo"
    "009_01_hipcc_hip.binfo"
    "009_02_hipcc_hipcc.binfo"
    "009_03_hipcc_clr.binfo"
    "010_rocm_smi_lib.binfo"
    "011_01_hwloc.binfo"
    "011_02_boost.binfo"
    "011_03_gtest.binfo"
    "011_04_half.binfo"
    "011_05_ucx_openmpi.binfo"
    "011_06_ucc_openmpi.binfo"
    "011_07_openmpi.binfo"
    "012_01_flang_libpgmath.binfo"
    "012_02_flang.binfo"
    "013_01_llvm_project_openmp.binfo"
    "013_02_flang_runtime.binfo"
    "013_03_llvm_project_openmp_fortran.binfo"
    "014_aomp_extras.binfo"
    "015_rocFFT.binfo"
    "016_01_rocBLAS_Tensile.binfo"
    "016_02_rocBLAS.binfo"
    "017_rocPRIM.binfo"
    "018_01_rocrand_hiprand.binfo"
    "018_02_rocrand_rocrand.binfo"
    "019_01_amd_fftw_single_precision.binfo"
    "019_02_amd_fftw_double_precision.binfo"
    "019_03_amd_fftw_long_double_precision.binfo"
    "019_04_amd_fftw_quad_precision.binfo"
    "019_05_hipFFT.binfo"
    "020_rocSPARSE.binfo"
    "021_hipSPARSE.binfo"
    "022_01_hipify.binfo"
    "022_02_rccl.binfo"
    "023_rocALUTION.binfo"
    "024_hipCUB.binfo"
    "025_clang-ocl.binfo"
    "026_01_miopen_rocMLIR.binfo"
    "026_02_miopengem.binfo"
    "027_01_functionalplus.binfo"
    "027_02_eigen.binfo"
    "027_03_frugally_deep.binfo"
    "027_04_composable_kernel.binfo"
    "028_rockthrust.binfo"
    "029_rocprofiler.binfo"
    "030_roctracer.binfo"
    "031_miopen.binfo"
    "032_01_rocSOLVER_fmt.binfo"
    "032_02_rocSOLVER_lapack.binfo"
    "032_03_rocSOLVER.binfo"
    "033_hipSOLVER.binfo"
    "034_hipBLAS.binfo"
    "035_rocWMMA.binfo"
    "036_magma.binfo"
    "037_01_pytorch.binfo"
    "037_02_pytorch_vision.binfo"
    "037_03_pytorch_audio.binfo"
)

LIST_BINFO_FILE_BASENAME_NOT_USED=(
    #"050_tensorflow_r11_hip_hcc.binfo"
    #"051_tensorflow_r21_hip_hcc.binfo"
)

FNAME_REPO_REVS_CUR=${SDK_ROOT_DIR}/binfo/repo_revs_cur.txt
FNAME_REPO_REVS_NEW=${SDK_ROOT_DIR}/binfo/repo_revs_new.txt

func_binfo_list_init_app_list() {
    LIST_BINFO_FILE_FULLNAME=()
    LIST_BINFO_APP_NAME=()
    LIST_APP_SRC_DIR=()
    LIST_APP_PATCH_DIR=()
    LIST_APP_UPSTREAM_REPO=()
    LIST_REPO_REVS_NEW=()
    LIST_REPO_REVS_CUR=()
    jj=0
    while [ "x${LIST_BINFO_FILE_BASENAME[jj]}" != "x" ]
    do
        #echo ${LIST_BINFO_FILE_BASENAME[jj]}

        unset BINFO_APP_UPSTREAM_REPO_URL
        unset BINFO_APP_SRC_CLONE_DIR
        unset BINFO_APP_SRC_DIR
        unset BINFO_APP_NAME
        unset BINFO_APP_UPSTREAM_REPO_VERSION_TAG

        LIST_BINFO_FILE_FULLNAME[$jj]=${SDK_ROOT_DIR}/binfo/${LIST_BINFO_FILE_BASENAME[${jj}]}

        #read build commands
        source ${LIST_BINFO_FILE_FULLNAME[${jj}]}
        if [ -v BINFO_APP_SRC_CLONE_DIR ]; then
            LIST_APP_SRC_CLONE_DIR[$jj]=${BINFO_APP_SRC_CLONE_DIR}
        else
            if [ -v BINFO_APP_SRC_DIR ]; then
                LIST_APP_SRC_CLONE_DIR[$jj]=${BINFO_APP_SRC_DIR}
            else
                echo "error, define for variable BINFO_APP_SRC_DIR missing: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
                exit 1
            fi
        fi

        if [ -v BINFO_APP_SRC_DIR ]; then
            LIST_APP_SRC_DIR[$jj]=${BINFO_APP_SRC_DIR}
        else
            echo "error, define for variable BINFO_APP_SRC_DIR missing: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            exit 1
        fi
        if [ -v BINFO_APP_NAME ]; then
            LIST_BINFO_APP_NAME[$jj]=${BINFO_APP_NAME}
            LIST_APP_PATCH_DIR[$jj]=${PATCH_FILE_ROOT_DIR}/${BINFO_APP_NAME}
        else
            echo "error, BINFO_APP_NAME npt defined: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            exit 1
        fi
        if [ -v BINFO_APP_UPSTREAM_REPO_URL ]; then
            LIST_APP_UPSTREAM_REPO[$jj]=${BINFO_APP_UPSTREAM_REPO_URL}
        else
            echo "error, BINFO_APP_UPSTREAM_REPO_URL not defined: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            exit 1
        fi

        if [ -v BINFO_APP_UPSTREAM_REPO_VERSION_TAG ]; then
            LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]=${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}
            #echo "BINFO_APP_UPSTREAM_REPO_VERSION_TAG: ${BINFO_APP_UPSTREAM_REPO_VERSION_TAG}"
        else
            #echo "UPSTREAM_REPO_VERSION_TAG_DEFAULT: ${UPSTREAM_REPO_VERSION_TAG_DEFAULT}"
            LIST_APP_UPSTREAM_REPO_VERSION_TAG[$jj]=${UPSTREAM_REPO_VERSION_TAG_DEFAULT}
            #echo "error, define for variable BINFO_APP_REPO_VERSION_TAG missing: ${LIST_BINFO_FILE_FULLNAME[${jj}]}"
            #exit 1
        fi
        jj=$(( ${jj} + 1 ))
    done
}
