# records microphone and saves the results to file.
# Copyright (c) 2024 Mika Laitio <lamikr@gmail.com> 

import torch
import torchaudio
import queue
import threading
from torchaudio.io import StreamWriter
from torchaudio.io import StreamReader
import time
from torchaudio.io import play_audio

_recording_enabled=False

print(torch.__version__)
print(torchaudio.__version__)

OUTPUT_FILE="microphone_rec.wav"

print("saving microphone to file:" + OUTPUT_FILE)

# define and configure the file where to save captured microphone data
writer = StreamWriter("./" + OUTPUT_FILE)
writer.add_audio_stream(
    sample_rate=48000,
    num_channels=1,
    format="s16"
)

# define method launc
def audio_streamer_thread(path):
    print("audio_streamer started, path: " + path)
    q = queue.Queue()
    print("audio_streamer done: " + path)
    # Streaming process that runs in background thread
    def run_audio_streamer_thread():
        streamer = StreamReader(src="-", format="pulse")
        for i in range(streamer.num_src_streams):
            print(streamer.get_src_stream_info(i))
        streamer.add_basic_audio_stream(
            frames_per_chunk=4096,
            sample_rate=48000,
            num_channels=1,
            format="s16"
        )        
        while not _recording_enabled:
            print("sleep")
            time.sleep(2)
        for (chunk_,) in streamer.stream():
            q.put(chunk_)
            if not _recording_enabled:
                print("Recording stopped")
                break
    # Start the background thread and fetch chunks
    t = threading.Thread(target=run_audio_streamer_thread)
    t.start()
    while _recording_enabled:
        try:
            yield q.get()
        except queue.Empty:
            print("empty")
            break
        except Exception as e:
            print("error")
            print(e)
            break
    t.join()

# open the audio streamer thread and save the chunks to output stream (file)
with writer.open():
    _recording_enabled=True
    ii=0
    for chunk in audio_streamer_thread("pulse"):
        try:
            ii = ii + 1
            if (ii > 100):
                print("Requesting to stop the recording")
                _recording_enabled = False
                break;
            writer.write_audio_chunk(0, chunk)
        except RuntimeError as re:
            _recording_enabled = False
            print(re)
            break
        except Exception as e:
            _recording_enabled = False
            print(e)
            break

waveform, sample_rate = torchaudio.load("./" + OUTPUT_FILE, channels_first=False, normalize=True)
print("play original audio")
play_audio(waveform, sample_rate)

effects = [
    ["speed", "0.85"],          # reduce speed
    ["lowpass", "-1", "320"],   # lowpass filter
    ["rate", f"{sample_rate}"], 
    ["reverb", "-w"],           # reverb
]

waveform2, sample_rate2 = torchaudio.sox_effects.apply_effects_tensor(waveform, sample_rate, effects, channels_first=False)
print("play recording with effects")
play_audio(waveform2, sample_rate2)

