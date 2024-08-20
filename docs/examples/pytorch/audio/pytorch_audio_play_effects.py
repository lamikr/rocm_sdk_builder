# loads and plays pytorch audio with different samples enabled
# based on to tutorial with fixes to get things working on pytorch 2.4.0 on Linux.
# Example wav files originates from the pytorch website
#
# Copyright (c) 2024 Mika Laitio <lamikr@gmail.com> 

import time
import torch
import torchaudio
from torchaudio.io import play_audio
from IPython.display import Audio
import torchaudio.functional as AUFUNC

try:
    print("audio load starting")
    waveform, sample_rate = torchaudio.load("./speech.wav", channels_first=False, normalize=True)
    print("play original audio")
    play_audio(waveform, sample_rate)
    print("play original audio done")

    effects1 = [
        ["speed", "0.85"],          # reduce speed
    ]
    effects2 = [
        ["lowpass", "-1", "320"],   # lowpass filter
    ]
    effects3 = [
        ["rate", f"{sample_rate}"],
    ]
    effects4 = [
        ["reverb", "-w"],           # reverb
    ]
    effects5 = [
        ["speed", "0.85"],          # reduce speed
        ["lowpass", "-1", "320"],   # lowpass filter
        ["rate", f"{sample_rate}"],
        ["reverb", "-w"],           # reverb
    ]    

    # start testing effects
    waveform2, sample_rate2 = torchaudio.sox_effects.apply_effects_tensor(waveform, sample_rate, effects1, channels_first=False)
    print("play effects1")
    play_audio(waveform2, sample_rate2)

    waveform2, sample_rate2 = torchaudio.sox_effects.apply_effects_tensor(waveform, sample_rate, effects2, channels_first=False)
    print("play effects2")
    play_audio(waveform2, sample_rate2)

    waveform2, sample_rate2 = torchaudio.sox_effects.apply_effects_tensor(waveform, sample_rate, effects3, channels_first=False)
    print("play effects3")
    play_audio(waveform2, sample_rate2)

    waveform2, sample_rate2 = torchaudio.sox_effects.apply_effects_tensor(waveform, sample_rate, effects4, channels_first=False)
    print("play effects4")
    play_audio(waveform2, sample_rate2)

    waveform2, sample_rate2 = torchaudio.sox_effects.apply_effects_tensor(waveform, sample_rate, effects5, channels_first=False)
    print("play effects5")
    play_audio(waveform2, sample_rate2)
    
    speech, _ = torchaudio.load("./speech.wav")
    print("speech.size: " + str(speech.size()))
    # cut the speech and noise tensor to be equal size
    speech = speech[:,0:40000]
    print("speech.size: " + str(speech.size()))
    noise, _ = torchaudio.load("./noise.wav")
    noise = noise[:,0:40000]
    snr_dbs = torch.tensor([10, 5])
    noisy_speeches = AUFUNC.add_noise(speech, noise, snr_dbs)
    torchaudio.save('./speech_resave.wav', noisy_speeches, sample_rate2)
    waveform2, sample_rate2 = torchaudio.load("./speech_resave.wav", channels_first=False, normalize=True)
    play_audio(waveform2, sample_rate2)
    
except Exception as e:
    print("play_audio exception")
    print(e)
