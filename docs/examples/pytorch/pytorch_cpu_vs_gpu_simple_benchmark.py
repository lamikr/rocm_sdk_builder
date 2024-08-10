import os
import platform
import subprocess
import re
import torch
import time

# problem parameters
mat_sz_x=200
mat_sz_y=200
loop_count=1200

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

print("Benchmarking CPU and GPUs")
print("Pytorch version: " + torch.__version__)
print("ROCM HIP version: " + torch.version.hip)

msg_prefix="Device: "
msg_prefix=msg_prefix.rjust(15)
print(msg_prefix + get_cpu_name(), flush=True)

###CPU
torch_device = torch.device('cpu')
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
    torch_device = torch.device('cuda:' + str(ii))
    torch.cuda.set_device(torch_device)
    msg_prefix="Device: "
    msg_prefix=msg_prefix.rjust(15)
    print(msg_prefix + torch.cuda.get_device_name(ii), flush=True)
    start_time = time.time()
    a = torch.ones(mat_sz_x, mat_sz_y, device=torch_device)
    b = torch.ones(mat_sz_x, mat_sz_y, device=torch_device)
    for _ in range(loop_count):
        a = torch.matmul(a, a+b)
    elapsed_time = time.time() - start_time
    msg_number="{:.3f}".format(elapsed_time)
    msg_prefix="'GPU time: "
    msg_prefix=msg_prefix.rjust(15)
    print(f"{msg_prefix}{msg_number} sec")
print("Benchmark ready\n")
