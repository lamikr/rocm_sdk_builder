# Example Applications

## Setup the rocm_sdk

ROCm SDK builder environment needs to be first set to environment variables
like path with following command:

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
```
Note that this command needs to be executed only once for each bash terminal session evenghouth we set it up on exery example below.

## Test Pytorch Install

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/pytorch
# ./run_pytorch_gpu_simple_test.sh
```

## Test Jupyter-notebook usage with Pytorch.

Following command will test that jupyter-notebook opens properly and
show information about installed pytorch version and your GPU.
(Note that AMD gpus are also handled as a cuda GPU on pytorch language)

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/pytorch
# jupyter-notebook pytorch_amd_gpu_intro.ipynb
```

## Test Pytorch MIGraphX integration

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/pytorch
# python test_torch_migraphx_resnet50.py
```

## Test MIGraphX

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/migraphx
# ./test_migraphx_install.sh
```

## Test ONNXRuntime

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/onnxruntime
# test_onnxruntime_providers.py*
```

This should printout: ['MIGraphXExecutionProvider', 'ROCMExecutionProvider', 'CPUExecutionProvider']

## Test HIPCC compiler

Following code shows how to transfer data to GPU and back
by using hipcc.

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/hipcc/hello_world
# ./build.sh
```

## Test OpenCL Integration

Following code printouts some information about OpenCL platform and devices found

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/opencl/check_opencl_caps
# make
# ./check_opencl_caps
```

Following code sends 200 numbers for GPU kernels which modifies and sends them back to userspace.

```
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# cd /opt/rocm_sdk_612/docs/examples/opencl/hello_world
# make
# ./hello_world
```

## Run Pytorch GPU Benchmark

This test is pretty extensive and takes about 50 minutes on RX 6800.
Test results are collected to result-folder but the python code which
is supposed to parse the results from CSV files and plot pictures needs to be fixed.

Results for different AMD and Nvidia GPUs are available in results folder.

```
# git clone https://github.com/lamikr/pytorch-gpu-benchmark/
# cd pytorch-gpu-benchmark
# source /opt/rocm_sdk_612/bin/env_rocm.sh
# ./test.sh
```
