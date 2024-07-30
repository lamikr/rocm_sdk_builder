# modified from original example at
# https://github.com/vllm-project/vllm/blob/main/examples/offline_inference.py

from vllm import LLM, SamplingParams

# Sample prompts.
prompts = [
    "Tell me about the quote 'Float like a butterfly, sting like a bee'",
    "Will Lauri Markkanen be traded to Golden State Warriors?",
    "Tell me about the story of Paavo Nurmi Statues in Swedish Vasa war ship?",
    "Who is Diego Maradona?"
]
# Create a sampling params object.
sampling_params = SamplingParams(temperature=0.8, top_p=0.95, max_tokens=128)

# Create an LLM.
#llm = LLM(model="facebook/opt-125m")
llm = LLM(model="facebook/opt-350m")
# Generate texts from the prompts. The output is a list of RequestOutput objects
# that contain the prompt, generated text, and other information.
outputs = llm.generate(prompts, sampling_params)
# Print the outputs.
for output in outputs:
    prompt = output.prompt
    generated_text = output.outputs[0].text
    print(f"\nPrompt: {prompt!r}")
    print("Answer:")
    print(f"{generated_text!r}")
