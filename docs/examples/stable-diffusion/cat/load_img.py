import torch
import triton
from PIL import Image
#from triton import ops
from diffusers import StableDiffusion3Pipeline

import matplotlib.pyplot as plt
import torchvision.io as tio

image1 = tio.read_image("image1.jpg")




# Convert the image to a numpy array 
# (matplotlib works with numpy arrays, not tensors directly)
image_np = image1.permute(1, 2, 0).numpy()

# Display the image
plt.imshow(image_np)
plt.axis("off")  # Turn off axis labels
plt.show()
