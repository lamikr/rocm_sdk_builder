#
# 1) launch vllm serve (it may take many minutes until it's ready)
# 2) install open-webui
#     - pip install open-webui
# 3) launch open-webui
#     - open-webui serve
# 4) connect to openwebui on port http://localhost:8080
# 5) click username/Admin Panel/Settings/Connections
#    - openai url: http://localhost:8000/v1
#    - openai token: token-abc123
# 6) Save settings
# 7) Go to Workspace/New Chat
#    - you should see now the model on top left as an model: DeepSeek-R1-Distill-Llama-8B-Q6_K.gguf

vllm serve deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B --tensor-parallel-size 1 --max-model-len 32768 --enforce-eager --api-key token-abc123 --chat-template ./template_chatglm.jinja
