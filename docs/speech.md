# Local speech with speech.cpp

Mise manages [speech.cpp](https://github.com/nyosegawa/speech.cpp), which provides
local speech recognition, text-to-speech, and voice activity detection through
the `speech` command. The configuration selects the Apple Silicon Metal release
for this macOS workstation and pins the executable version in `mise/config.toml`.

## Install and check

After merging and updating the checkout:

```sh
mise install --locked github:nyosegawa/speech.cpp
mise which speech
speech --version
speech devices
```

Use Mise to update the version and lockfile rather than `speech update` or the
upstream installer, so Mise remains the owner of the executable.

## Transcribe

Start with Qwen3-ASR 0.6B and Silero voice activity detection:

```sh
speech asr qwen3-asr-0.6b --vad silero-vad recording.wav
speech asr qwen3-asr-0.6b --vad silero-vad --live
```

The live command uses the default microphone until Ctrl-C; allow microphone
access for the terminal when macOS requests it. Models download on first use:
Qwen3-ASR 0.6B is about 0.84 GB and Silero VAD about 1.2 MB. Model downloads are
managed by speech.cpp and cached under `~/Library/Caches/speech.cpp`; they are
separate from Mise's executable lockfile.

Use VAD to split recordings at speech boundaries. Qwen3-ASR does not provide
timestamps or its upstream model's native streaming; speech.cpp implements live
transcription around repeated recognition. For English and other supported
European languages with timestamps:

```sh
speech asr parakeet-tdt-0.6b-v3 --vad silero-vad --timestamps recording.wav
```

## Speak and serve

```sh
speech tts qwen3-tts-0.6b --voice ryan -o hello.wav "Hello from this Mac."
speech serve qwen3-tts-0.6b qwen3-asr-0.6b
```

The TTS model downloads about 1.21 GB on first use. The server listens on
`127.0.0.1:8080` by default and provides OpenAI-compatible speech and transcription
endpoints. It has no authentication; keep the default loopback binding for local
use.

## Hardware expectations

The M4 workstation with 16 GB unified memory is a reasonable starting point for
the 0.6B models. Upstream reports about 1 GB peak process memory for Qwen3-ASR
0.6B on short utterances on an M5. That is a sizing reference, not an M4 latency
measurement or a memory bound for long recordings, concurrent models, or a local
LLM running alongside speech.

See the upstream [model catalog](https://github.com/nyosegawa/speech.cpp/blob/main/docs/models.md),
[Qwen3-ASR limitations and measurements](https://github.com/nyosegawa/speech.cpp/blob/main/docs/models/qwen3-asr.md),
and [server documentation](https://github.com/nyosegawa/speech.cpp/blob/main/docs/server.md).
