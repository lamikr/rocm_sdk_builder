ROCM SDK Builder

# Purpose
Build the AMD ROCM SDK with GPU support for user-level AMD GPUs like
RX 5700, RX 6800 and m680i. In addition the system will also build and install projects like python3.9
and pytorch with their dependencies under SDK directory to provide tested execution environment. 
Build system has been only tested on Linux.

List of projects build can be configured via binfo/binfo.sh file where they
are at the moment arranged to list in build dependency order.
Each project has also their own binfo/project_name.binfo file for project specific build configuration.

# How to build the ROCM_SDK with support for specific GPU

1) select target GPU's by commenting/uncommenting following from the
binfo/envsetup.sh

GPU_ARCH_BUILD_NAVI21=1 (for Amd rx 6800/gfx1030)
#GPU_ARCH_BUILD_REMBRANDT=1 (for Amd m680i mobile gpu / gfx1035)
#GPU_ARCH_BUILD_NAVI10=1 (for amd rx 5700 / gfx1010)

2) Init the system by cloning the source code for projects build from the github (abroximately 20 gb)
./babs.sh -i

3) Build the AMD ROCm SDK to /opt/rocm_sdk_version directory
./babs.sh -b

AMD ROCM SDK build will required many hours and require approximately 24 gb of space.
Build system can be cleaned by removing the builddir directory.

patches-directory in build system contains various patches that are required for AMD's rocm components.  
to enable the support for user level GPU's like AMD RX 5700, RX 6800 and m680 integrated mobile GPU's.
Build system will apply those patches automatically to required projects during the ./babs.sh -i invocation.

# SDK Usage

1) Init environment variables and paths 
# source /opt/rocm_sdk_571/bin/env_rocm.sh

2) Test the gpu detection
# rocm-info

3) Test the pytorch
# jupyter-notebook

4) gpu benchmark
https://github.com/lamikr/pytorch-gpu-benchmark contains common benhmark that
is usually used for testing NVIDIA gpu. I have updated it for never pytorch/python versions
and added "test_with_torchvision_013.sh script for testing with amd gpu's)

# Additional build commands

babs.sh has also following commands
./babs.sh -co (checkouts the sources back to basic level for all projects)
./babs.sh -ap (apply patches to checked sources for all projects)
./babs.sh -f (fetch latest sources for all projects)
./babsh.sh -fs (fetch latest sources for all projects all submodules)

Re-building of single projects can be controlled by deleting their build-files from builddir-directory.
More detailed project build phase specific tuning is also possible by deleting build-phase result files.
(builddir/project/.result_preconfig/config/postconfig/build/install/postinstall)

Copyright (C) 2023 by Mika Laitio <lamikr@gmail.com>
