import torch
import time
import os

###CPU
device = torch.device('cpu')
mat_sz_x=200
mat_sz_y=200
loop_count=1200

print("Benchmarking CPU and GPUs")
print("Pytorch version: " + torch.__version__)
print("ROCM HIP version: " + torch.version.hip)

msg_prefix="Device: "
msg_prefix=msg_prefix.rjust(15)
print(msg_prefix + "cpu-" + str(os.cpu_count()))

start_time = time.time()
a = torch.ones(mat_sz_x, mat_sz_y)
b = torch.ones(mat_sz_x, mat_sz_y)
for _ in range(loop_count):
    a = torch.matmul(a, a+b)
elapsed_time = time.time() - start_time
msg_number="{:.3f}".format(elapsed_time)
msg_prefix="'CPU time: "
msg_prefix=msg_prefix.rjust(15)
print(f"{msg_prefix}{msg_number} sec")

###GPUs
gpu_count=torch.cuda.device_count()
for ii in range(0, gpu_count):
    cuda_device = torch.device('cuda:' + str(ii))
    torch.cuda.set_device(cuda_device)
    msg_prefix="Device: "
    msg_prefix=msg_prefix.rjust(15)
    print(msg_prefix + torch.cuda.get_device_name(ii))
    start_time = time.time()
    a = torch.ones(mat_sz_x, mat_sz_y, device=cuda_device)
    b = torch.ones(mat_sz_x, mat_sz_y, device=cuda_device)
    for _ in range(loop_count):
        a = torch.matmul(a, a+b)
    elapsed_time = time.time() - start_time
    msg_number="{:.3f}".format(elapsed_time)
    msg_prefix="'GPU time: "
    msg_prefix=msg_prefix.rjust(15)
    print(f"{msg_prefix}{msg_number} sec")
print("Benchmark ready\n")
