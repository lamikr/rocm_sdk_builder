import torch

print("1) Expected configuration: enable_flash=True, enable_math=False, enable_mem_efficient=False")
print("Real configuration:")
with torch.nn.attention.sdpa_kernel(torch.nn.attention.SDPBackend.FLASH_ATTENTION):
    print("    cuda.flash_sdp_enabled: " + str(torch.backends.cuda.flash_sdp_enabled()))
    # True
    print("    cuda.mem_efficient_sdp_enabled: " + str(torch.backends.cuda.mem_efficient_sdp_enabled()))
    # False
    print("    cuda.math_sdp_enabled: " + str(torch.backends.cuda.math_sdp_enabled()))
    # False

print("")
print("2) Expected configuration: enable_flash=False, enable_math=True, enable_mem_efficient=True")
print("Real configuration:")
with torch.nn.attention.sdpa_kernel([torch.nn.attention.SDPBackend.MATH, torch.nn.attention.SDPBackend.EFFICIENT_ATTENTION]):
    print("    cuda.flash_sdp_enabled: " + str(torch.backends.cuda.flash_sdp_enabled()))
    # False
    print("    cuda.mem_efficient_sdp_enabled: " + str(torch.backends.cuda.mem_efficient_sdp_enabled()))
    # True
    print("    cuda.math_sdp_enabled: " + str(torch.backends.cuda.math_sdp_enabled()))
    # True
