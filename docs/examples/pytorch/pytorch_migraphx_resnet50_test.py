import torch
import torchvision
import torch_migraphx

print("pytorch migraphx resnet50 benchmark")
resnet = torchvision.models.resnet50()
sample_input = torch.randn(2, 3, 64, 64)
resnet_mgx = torch_migraphx.fx.lower_to_mgx(resnet, [sample_input])
result = resnet_mgx(sample_input)

print("Pytorch version: " + torch.__version__)
print("ROCM HIP version: " + torch.version.hip)
print(result)
print("Benhmark ready")
