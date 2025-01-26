import torch
import triton
from PIL import Image
from diffusers import StableDiffusion3Pipeline

pipe = StableDiffusion3Pipeline.from_pretrained("stabilityai/stable-diffusion-3-medium-diffusers",torch_dtype=torch.float16)
pipe = pipe.to("cuda")

torch_gen = torch.Generator("cuda")
torch_gen.manual_seed(2024)

image1 = pipe(
    "A cat holding a sign that says hello world",
    negative_prompt="",
    num_inference_steps=32,
    guidance_scale=6.0,
    generator=torch_gen
).images[0]
image1.save("image1.jpg")
image1.show()

image2 = pipe(
    "A cat holding a sign that says hello world",
    negative_prompt="",
    num_inference_steps=32,
    guidance_scale=6.0,
    generator=torch_gen
).images[0]
image2.save("image2.jpg")
image2.show()
