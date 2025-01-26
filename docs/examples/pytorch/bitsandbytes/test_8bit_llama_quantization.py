from transformers import LlamaForCausalLM
from transformers import BitsAndBytesConfig

model = 'facebook/opt-350m'
model = LlamaForCausalLM.from_pretrained(model, quantization_config=BitsAndBytesConfig(load_in_8bit=True))
