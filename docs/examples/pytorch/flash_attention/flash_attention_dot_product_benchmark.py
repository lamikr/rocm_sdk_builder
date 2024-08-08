import os
import torch
import torch.nn as nn
import torch.nn.functional as F

# copyright (C) Mika Laitio, lamikr@gmail.com
# dot product calculation benchmark test based on the documentation at
# https://pytorch.org/tutorials/intermediate/scaled_dot_product_attention_tutorial.html

dev_type_arr = ["cuda:0", "cpu"]
solver_name_arr=["Default", "Math", "Flash Attention", "Memory Efficient"]

# testing
print("Pytorch version: " + torch.__version__)
print("dot product calculation test")
query, key, value = torch.randn(2, 3, 8, device=dev_type_arr[0]), torch.randn(2, 3, 8, device=dev_type_arr[0]), torch.randn(2, 3, 8, device=dev_type_arr[0])
print(F.scaled_dot_product_attention(query, key, value))

import torch.utils.benchmark as benchmark
def benchmark_torch_function_in_microseconds(f, *args, **kwargs):
    t0 = benchmark.Timer(
        stmt="f(*args, **kwargs)", globals={"args": args, "kwargs": kwargs, "f": f}
    )
    return t0.blocked_autorange().mean * 1e6

# benchmark parameters
batch_size = 32
max_sequence_len = 1024
num_heads = 32
embed_dimension = 32
dtype = torch.float16

result_arr=[[0, 0, 0, 0], [0, 0, 0, 0]]

print("")
print("Benchmarking cuda and cpu with Default, Math, Flash Attention amd Memory pytorch backends")

for ii, dev_type_item in enumerate(dev_type_arr):
    if dev_type_item == "cpu":
        print("Device: cpu-" + str(os.cpu_count()))
    else:
        print("Device: " + torch.cuda.get_device_name(device=dev_type_item))
    query = torch.rand(batch_size, num_heads, max_sequence_len, embed_dimension, device=dev_type_item, dtype=dtype)
    key   = torch.rand(batch_size, num_heads, max_sequence_len, embed_dimension, device=dev_type_item, dtype=dtype)
    value = torch.rand(batch_size, num_heads, max_sequence_len, embed_dimension, device=dev_type_item, dtype=dtype)

    print("    " + solver_name_arr[0] + " " + dev_type_item + " benchmark:")
    result_arr[ii][0]=benchmark_torch_function_in_microseconds(F.scaled_dot_product_attention, query, key, value)
    print(f"        {result_arr[ii][0]:.3f} microseconds, {(result_arr[ii][0] / 1e6)} sec")

    # Lets explore the speed of each of the 3 implementations
    from torch.nn.attention import SDPBackend, sdpa_kernel

    print("    " + solver_name_arr[1] + " " + dev_type_item + " benchmark:")
    with sdpa_kernel(SDPBackend.MATH):
        result_arr[ii][1]=benchmark_torch_function_in_microseconds(F.scaled_dot_product_attention, query, key, value)
        print(f"        {result_arr[ii][1]:.3f} microseconds, {(result_arr[ii][1] / 1e6)} sec")

    print("    " + solver_name_arr[2] + " " + dev_type_item + " benchmark:")
    with sdpa_kernel(SDPBackend.FLASH_ATTENTION):
        try:
            result_arr[ii][2]=benchmark_torch_function_in_microseconds(F.scaled_dot_product_attention, query, key, value)
            print(f"        {result_arr[ii][2]:.3f} microseconds, {(result_arr[ii][2] / 1e6)} sec")
        except RuntimeError:
            print("    " + solver_name_arr[2] + " " + dev_type_item + " is not supported. See warnings for reasons.")
            result_arr[ii][2]=-1

    print("    " + solver_name_arr[3] + " " + dev_type_item + " benchmark:")
    with sdpa_kernel(SDPBackend.EFFICIENT_ATTENTION):
        try:
            result_arr[ii][3]=benchmark_torch_function_in_microseconds(F.scaled_dot_product_attention, query, key, value)
            print(f"        {result_arr[ii][3]:.3f} microseconds, {(result_arr[ii][3] / 1e6)} sec")
        except RuntimeError:
            print("    " + solver_name_arr[3] + " " + dev_type_item + " is not supported. See warnings for reasons.")
            result_arr[ii][3]=-1

print("Summary")
print("\nPytorch version: " + torch.__version__)
print("ROCM HIP version: " + torch.version.hip)
for ii, dev_type_item in enumerate(dev_type_arr):
    if dev_type_item == "cpu":
        print("Device: cpu-" + str(os.cpu_count()))
    else:
        print("Device: " + torch.cuda.get_device_name(device=dev_type_item))
    for jj, result_item in enumerate(solver_name_arr):
        msg_prefix=solver_name_arr[jj] + " " + dev_type_arr[ii] + ":"
        msg_prefix=msg_prefix.rjust(30)
        msg_number="{:.3f}".format(result_arr[ii][jj])
        msg_number=msg_number.rjust(20)
        print(f"{msg_prefix} {msg_number} ms")
    print("")
