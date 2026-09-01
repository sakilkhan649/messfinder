import wave
import struct
import math
import os

os.makedirs('assets/audio', exist_ok=True)
sample_rate = 44100
duration = 6.0
volume = 0.5
f1 = 440.0
f2 = 480.0
num_samples = int(sample_rate * duration)

wavef = wave.open('assets/audio/ringback.wav', 'w')
wavef.setnchannels(1)
wavef.setsampwidth(2)
wavef.setframerate(sample_rate)

for i in range(num_samples):
    t = float(i) / sample_rate
    # 2 seconds on, 4 seconds off
    if t % 6.0 < 2.0:
        value = int(volume * 32767.0 * (math.sin(2.0 * math.pi * f1 * t) + math.sin(2.0 * math.pi * f2 * t)) / 2.0)
    else:
        value = 0
    wavef.writeframesraw(struct.pack('<h', value))
    
wavef.close()
