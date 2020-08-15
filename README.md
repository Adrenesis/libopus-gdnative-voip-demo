# godot-voip-opus-demo EX
A more complex demo showing how to implement voip with libOpus compression and audio bus management.

The base of this project was copied from:
https://github.com/cbarsugman/godot-voip-demo
then from:
https://github.com/Godot-Opus/libopus-gdnative-voip-demo

## Opus Compression
Probably the biggest problem preventing VOIP from being implemented in Godot is the issue of compression.

In the original VOIP demo by cbarsugam, recorded audio is transmitted as raw PCM data. This is the type of data inside of a `.wav` file. It is loseless raw audio samples, and it is huge. Far too large for a real game to transmit over the internet between players.

What this project does, is it used the [Godot-Opus wrapper](https://github.com/Godot-Opus/libopus-gdnative-asset) to compress the data before transmission, and on the receiving side decompress the data before playback.

The compressed data is often more than 100 times smaller than the raw PCM data making this feasible for a real project.

## Displayer
The big update of this fork is his interface allowing to have sound of each player on separate audio bus, with settings for each player and the textual chat.

## Addon usage
```
Autoload Setup:
    Go to project settings
    Go to Autoload and load "/addons/adrenesis.opusLobby/Network.gd"
```

```
Audio Bus Setup:
    Go to Audio Bottom Panel
    Add an AudioBus named "RecordLoopback"
    Redirect that bus to "Master"
    Add an AudioBus named "Record"
    Add an AudioMicrophoneEffect on it
    Redirect that bus to RecordLoopBack
```

## What this is not: Streaming audio
This is a very simple form of VOIP. Press a button to record an audio sample. Only when the recording is completed is it compressed as a whole and sent to the remote clients. Then on the receiving end it is decompressed as a whole, and played back.

So this is very clearly not real-time voice chat. libOpus is specifically designed however to accomidate real-time voice chat and has many advanced features to facilitate it, which we are not using here.

However I beleive there is work that needs to be done inside Godot it's self to allow for the implementation of true real-time streaming audio.
