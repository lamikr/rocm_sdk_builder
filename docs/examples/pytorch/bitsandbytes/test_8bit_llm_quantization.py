# example from https://rocm.blogs.amd.com/artificial-intelligence/bnb-8bit/README.html
# changes to original example:
# - use google-t5/t5-small instead of google-t5/t5-3b so that loaded
#   model is only 300mb instead of 10gb. (Suits better for fast testing)

from datasets import load_dataset
from evaluate import load
from transformers import AutoTokenizer
from transformers import T5ForSequenceClassification
from transformers import TrainingArguments, Trainer, TrainerCallback
import numpy as np
import bitsandbytes as bnb
import torch
from sys import argv

dataset = load_dataset("glue", data_dir="cola")
metric = load("glue", "cola")
model_checkpoint = "google-t5/t5-small"

tokenizer = AutoTokenizer.from_pretrained(model_checkpoint, use_fast=True)

def preprocess_fun(examples):
    return tokenizer(examples["sentence"], truncation=True)

dataset = dataset.map(preprocess_fun, batched=True)

model = T5ForSequenceClassification.from_pretrained(model_checkpoint, device_map='cuda', torch_dtype=torch.float16)

train_args = TrainingArguments(
    f"T5-finetuned-cola",
    evaluation_strategy = "epoch",
    save_strategy = "epoch",
    learning_rate=2e-5,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    num_train_epochs=1,
    load_best_model_at_end=True
)

def compute_metrics(eval_pred):
    predictions, labels = eval_pred
    # print(predictions)
    predictions = np.argmax(predictions[0], axis=1)
    return metric.compute(predictions=predictions, references=labels)

if argv[-1]=='1':
    print("Using bnb's 8-bit Adam optimizer")
    adam = bnb.optim.Adam8bit(model.parameters())
else:
    adam = None # defaults to regular Adam

trainer = Trainer(
    model,
    train_args,
    train_dataset=dataset["validation"],
    eval_dataset=dataset["validation"],
    tokenizer=tokenizer,
    compute_metrics=compute_metrics,
    optimizers = (adam,None)
)
trainer.train()
