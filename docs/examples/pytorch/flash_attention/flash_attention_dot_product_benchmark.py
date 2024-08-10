import os
import time
import platform
import subprocess
import re
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.utils.benchmark as benchmark
from torch.nn.attention import SDPBackend, sdpa_kernel

# copyright (C) 2024 Mika Laitio, lamikr@gmail.com
# dot product calculation benchmark test based on the documentation at
# https://pytorch.org/tutorials/intermediate/scaled_dot_product_attention_tutorial.html

# by default benchmark all cuda devices and cpu
dev_type_arr=[]
gpu_count=torch.cuda.device_count()
for ii in range(0, gpu_count):
    torch_device = torch.device('cuda:' + str(ii))
    dev_type_arr.append(torch_device)
dev_type_arr.append("cpu")

# manually override the selection of devices to be benchmarked
# dev_type_arr = ["cuda:0", "cuda:1", "cpu"]

# benchmark problem parameters
max_sequence_len = 512
batch_size = 32
num_heads = 16
embed_dimension = 16
dtype = torch.float16

# dummy class needed for handling the default algorithm selection
class DefaultAlgorithmMC(type):
  def __repr__(self):
    return 'Default'
class DefaultAlgorithm(object, metaclass=DefaultAlgorithmMC):
    pass

# list of algorithms benchmarked
#algorithm_name_arr=["Default", "Math", "Flash Attention", "Memory Efficient"]
algorithm_name_arr=[DefaultAlgorithm, SDPBackend.MATH, SDPBackend.FLASH_ATTENTION, SDPBackend.EFFICIENT_ATTENTION]

# create 2-dimensional array for storing results dynamically
# depending from the algorithms used
single_res_arr=[]
for ii in range(len(algorithm_name_arr)):
    single_res_arr.append(0)
result_arr=[single_res_arr]
for ii in range((len(dev_type_arr) - 1)):
    single_res_arr=[]
    for ii in range(len(algorithm_name_arr)):
        single_res_arr.append(0)
    result_arr.append(single_res_arr)

# pytorch does not have good method to return cpu info via python api
# and platform.processor method seems to return empty string on my linux
# using the code snippet from stackoverflow
def get_cpu_name():
    if platform.system() == "Windows":
        return platform.processor()
    elif platform.system() == "Darwin":
        os.environ['PATH'] = os.environ['PATH'] + os.pathsep + '/usr/sbin'
        cmd ="sysctl -n machdep.cpu.brand_string"
        return subprocess.check_output(cmd).strip()
    elif platform.system() == "Linux":
        cmd = "cat /proc/cpuinfo"
        all_info = subprocess.check_output(cmd, shell=True).decode().strip()
        for text_str in all_info.split("\n"):
            if "model name" in text_str:
                return re.sub( ".*model name.*:", "", text_str, 1)
    return ""

cpu_name=get_cpu_name()

# testing
print("Pytorch version: " + torch.__version__)
print("dot product calculation test")
query, key, value = torch.randn(2, 3, 8, device=dev_type_arr[0]), torch.randn(2, 3, 8, device=dev_type_arr[0]), torch.randn(2, 3, 8, device=dev_type_arr[0])
print(F.scaled_dot_product_attention(query, key, value))

def benchmark_torch_function_in_microseconds(f, *args, **kwargs):
    t0 = benchmark.Timer(
        stmt="f(*args, **kwargs)", globals={"args": args, "kwargs": kwargs, "f": f}
    )
    return t0.blocked_autorange().mean * 1e6

print("")
print("Benchmarking cuda and cpu with Default, Math, Flash Attention amd Memory pytorch backends")

for ii, dev_type_item in enumerate(dev_type_arr):
    query = torch.rand(batch_size, num_heads, max_sequence_len, embed_dimension, device=dev_type_item, dtype=dtype)
    key   = torch.rand(batch_size, num_heads, max_sequence_len, embed_dimension, device=dev_type_item, dtype=dtype)
    value = torch.rand(batch_size, num_heads, max_sequence_len, embed_dimension, device=dev_type_item, dtype=dtype)

    dev_type_str=str(dev_type_item)
    if dev_type_str == "cpu":
        print("Device: " + cpu_name + " / " + dev_type_str)
    else:
        print("Device: " + torch.cuda.get_device_name(device=dev_type_item) + " / " + dev_type_str)

    # execution of all benchmarks starts from here
    for jj in range(len(algorithm_name_arr)):
        print("    " + str(algorithm_name_arr[jj]) + " benchmark:", flush=True)
        if algorithm_name_arr[jj] == DefaultAlgorithm:
            # execute the default algorithm without specifying the backend
            result_arr[ii][0]=benchmark_torch_function_in_microseconds(F.scaled_dot_product_attention, query, key, value)
            print(f"        {result_arr[ii][0]:.3f} microseconds, {(result_arr[ii][0] / 1e6)} sec")
        else:
            # execute one the SDPBackend algoriths (math, flash or memory efficient)
            with sdpa_kernel(algorithm_name_arr[jj]):
                try:
                    result_arr[ii][jj]=benchmark_torch_function_in_microseconds(F.scaled_dot_product_attention, query, key, value)
                    print(f"        {result_arr[ii][jj]:.3f} microseconds, {(result_arr[ii][jj] / 1e6)} sec")
                except RuntimeError:
                    print("    " + str(algorithm_name_arr[jj]) + " " + dev_type_str + " is not supported. See warnings for reasons.")
                    result_arr[ii][jj]=-1
        time.sleep(5)

print("Summary")
print("\nPytorch version: " + torch.__version__)
print("ROCM HIP version: " + torch.version.hip)
print("CPU: " + cpu_name)
print("Problem parameters:")
print("    Sequence-length: " + str(max_sequence_len))
print("    Batch-size: " + str(batch_size))
print("    Heads: " + str(num_heads))
print("    Embed_dimension: " + str(embed_dimension))
print("    Datatype: " + str(dtype))

for ii, dev_type_item in enumerate(dev_type_arr):
    dev_type_str=str(dev_type_item)
    if dev_type_str == "cpu":
        print("Device: " + cpu_name + " / " + dev_type_str)
    else:
        print("Device: " + torch.cuda.get_device_name(device=dev_type_item) + " / " + dev_type_str)
    for jj, result_item in enumerate(algorithm_name_arr):
        msg_prefix=str(algorithm_name_arr[jj]) + ":"
        msg_prefix=msg_prefix.rjust(35)
        msg_number="{:.3f}".format(result_arr[ii][jj])
        msg_number=msg_number.rjust(15)
        print(f"{msg_prefix} {msg_number} ms")
    print("")
