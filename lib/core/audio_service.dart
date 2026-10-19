import 'dart:async';
import 'dart:math';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'constants.dart';
import 'save_service.dart';

// ============================================================================
// PROCEDURAL WAV SYNTHESIZER
// ============================================================================

/// Audio sample rate for synthesized sound effects and ambient music.
const int kSampleRate = 22050;

/// Creates a complete 16-bit PCM WAV file byte buffer from [pcmSamples].
Uint8List createWavHeader(
  Int16List pcmSamples, {
  int sampleRate = kSampleRate,
}) {
  final int numSamples = pcmSamples.length;
  final int dataSize = numSamples * 2;
  final int fileSize = 36 + dataSize;

  final ByteData buffer = ByteData(44 + dataSize);

  // RIFF Chunk
  buffer.setUint8(0, 0x52); // 'R'
  buffer.setUint8(1, 0x49); // 'I'
  buffer.setUint8(2, 0x46); // 'F'
  buffer.setUint8(3, 0x46); // 'F'
  buffer.setUint32(4, fileSize, Endian.little);
  buffer.setUint8(8, 0x57); // 'W'
  buffer.setUint8(9, 0x41); // 'A'
  buffer.setUint8(10, 0x56); // 'V'
  buffer.setUint8(11, 0x45); // 'E'

  // fmt Subchunk
  buffer.setUint8(12, 0x66); // 'f'
  buffer.setUint8(13, 0x6D); // 'm'
  buffer.setUint8(14, 0x74); // 't'
  buffer.setUint8(15, 0x20); // ' '
  buffer.setUint32(16, 16, Endian.little); // Subchunk1Size
  buffer.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  buffer.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
  buffer.setUint16(32, 2, Endian.little); // BlockAlign
  buffer.setUint16(34, 16, Endian.little); // BitsPerSample

  // data Subchunk
  buffer.setUint8(36, 0x64); // 'd'
  buffer.setUint8(37, 0x61); // 'a'
  buffer.setUint8(38, 0x74); // 't'
  buffer.setUint8(39, 0x61); // 'a'
  buffer.setUint32(40, dataSize, Endian.little);

  // Copy Int16 PCM samples
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    buffer.setInt16(offset, pcmSamples[i], Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}

/// Helper synthesizer generating PCM audio buffers for game sound effects.
class SoundSynth {
  static final Random _rng = Random(12345);

  static Int16List generateSfx(SfxName name, {int sampleRate = kSampleRate}) {
    switch (name) {
      case SfxName.pop:
        return _synthPop(sampleRate);
      case SfxName.shoot:
        return _synthShoot(sampleRate);
      case SfxName.bounce:
        return _synthBounce(sampleRate);
      case SfxName.click:
        return _synthClick(sampleRate);
      case SfxName.star:
        return _synthStar(sampleRate);
      case SfxName.win:
        return _synthWin(sampleRate);
      case SfxName.lose:
        return _synthLose(sampleRate);
      case SfxName.whoosh:
        return _synthWhoosh(sampleRate);
      case SfxName.coin:
        return _synthCoin(sampleRate);
      case SfxName.boom:
        return _synthBoom(sampleRate);
      case SfxName.combo:
        return _synthCombo(sampleRate);
      case SfxName.thud:
        return _synthThud(sampleRate);
      case SfxName.tick:
        return _synthTick(sampleRate);
    }
  }

  static Int16List _synthPop(int sr) {
    const duration = 0.08;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 650.0 * (1.0 - t * 0.75); // Pitch drop 650Hz -> 160Hz
      phase += 2 * pi * freq / sr;
      final env = (1.0 - t) * (i < 50 ? i / 50 : 1.0);
      final val = sin(phase) * env * 0.8;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthShoot(int sr) {
    const duration = 0.14;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 800.0 * pow(0.2, t); // Swoosh pitch drop
      phase += 2 * pi * freq / sr;
      final noise = _rng.nextDouble() * 2 - 1;
      final env = sin(t * pi);
      final val = (sin(phase) * 0.6 + noise * 0.4) * env * 0.7;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthBounce(int sr) {
    const duration = 0.12;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 180.0 + sin(t * pi * 2) * 80.0;
      phase += 2 * pi * freq / sr;
      final env = (1.0 - t) * (i < 30 ? i / 30 : 1.0);
      final val = sin(phase) * env * 0.75;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthClick(int sr) {
    const duration = 0.03;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final env = pow(1.0 - t, 4).toDouble();
      final noise = _rng.nextDouble() * 2 - 1;
      final val = noise * env * 0.6;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthStar(int sr) {
    const duration = 0.38;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);

    // Arpeggio notes: C6, E6, G6, C7
    final frequencies = [1046.50, 1318.51, 1567.98, 2093.00];

    for (int i = 0; i < numSamples; i++) {
      final t = i / sr;
      final noteIndex = ((t / duration) * frequencies.length).floor().clamp(
        0,
        3,
      );
      final noteFreq = frequencies[noteIndex];
      final noteT = (t - (noteIndex * duration / frequencies.length));

      final phase = 2 * pi * noteFreq * noteT;
      final env = exp(-noteT * 12.0);
      final val = (sin(phase) + 0.3 * sin(phase * 2)) * env * 0.6;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthWin(int sr) {
    const duration = 0.6;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);

    final freqs = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6

    for (int i = 0; i < numSamples; i++) {
      final t = i / sr;
      final noteIdx = ((t / duration) * freqs.length).floor().clamp(0, 3);
      final f = freqs[noteIdx];
      final noteTime = t - (noteIdx * duration / freqs.length);

      final phase = 2 * pi * f * noteTime;
      final env = exp(-noteTime * 6.0);
      final val = (sin(phase) + 0.25 * sin(phase * 3)) * env * 0.7;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthLose(int sr) {
    const duration = 0.55;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);

    final freqs = [392.00, 369.99, 349.23, 329.63]; // G4, F#4, F4, E4

    for (int i = 0; i < numSamples; i++) {
      final t = i / sr;
      final noteIdx = ((t / duration) * freqs.length).floor().clamp(0, 3);
      final f = freqs[noteIdx];
      final noteTime = t - (noteIdx * duration / freqs.length);

      final phase = 2 * pi * f * noteTime;
      final env = exp(-noteTime * 5.0);
      final val = sin(phase) * env * 0.7;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthWhoosh(int sr) {
    const duration = 0.25;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);
    double filterOut = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final noise = _rng.nextDouble() * 2 - 1;
      final cutoff = sin(t * pi) * 0.4 + 0.05; // Sweeping filter
      filterOut += cutoff * (noise - filterOut);
      final env = sin(t * pi);
      final val = filterOut * env * 0.8;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthCoin(int sr) {
    const duration = 0.22;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);

    const f1 = 987.77; // B5
    const f2 = 1318.51; // E6

    for (int i = 0; i < numSamples; i++) {
      final t = i / sr;
      final env = exp(-t * 10.0);
      final s1 = sin(2 * pi * f1 * t);
      final s2 = sin(2 * pi * f2 * t);
      final val = (s1 + s2) * 0.4 * env;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthBoom(int sr) {
    const duration = 0.45;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);
    double phase = 0.0;
    double filterOut = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final subFreq = 90.0 * (1.0 - t * 0.7); // Sub-bass drop
      phase += 2 * pi * subFreq / sr;

      final noise = _rng.nextDouble() * 2 - 1;
      final cutoff = (1.0 - t) * 0.3 + 0.02;
      filterOut += cutoff * (noise - filterOut);

      final env = exp(-t * 5.0);
      final val = (sin(phase) * 0.6 + filterOut * 0.4) * env * 0.85;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthCombo(int sr) {
    const duration = 0.32;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 523.25 + (t * 800.0); // Rising pitch sweep
      phase += 2 * pi * freq / sr;

      final env = sin(t * pi);
      final val = (sin(phase) + 0.2 * sin(phase * 2)) * env * 0.7;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthThud(int sr) {
    const duration = 0.15;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 130.0 * (1.0 - t * 0.6);
      phase += 2 * pi * freq / sr;

      final env = exp(-t * 12.0);
      final val = sin(phase) * env * 0.8;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  static Int16List _synthTick(int sr) {
    const duration = 0.02;
    final numSamples = (sr * duration).toInt();
    final pcm = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final phase = 2 * pi * 1400.0 * (i / sr);
      final env = exp(-t * 80.0);
      final val = sin(phase) * env * 0.5;
      pcm[i] = (val * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }

  /// Synthesizes a 16-second ambient space loop.
  static Int16List generateAmbientMusicLoop({int sampleRate = kSampleRate}) {
    const duration = 16.0;
    final numSamples = (sampleRate * duration).toInt();
    final pcm = Int16List(numSamples);

    // Ambient space chord frequencies (C minor 9 / Eb major 7)
    final padFreqs = [
      130.81,
      155.56,
      196.00,
      233.08,
      293.66,
    ]; // C3, Eb3, G3, Bb3, D4
    final arpFreqs = [
      523.25,
      622.25,
      783.99,
      932.33,
      1174.66,
    ]; // C5, Eb5, G5, Bb5, D6

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Soft breathing pad
      double padVal = 0.0;
      final lfo = sin(2 * pi * t / 8.0) * 0.15 + 0.85; // Slow LFO

      for (int k = 0; k < padFreqs.length; k++) {
        final f = padFreqs[k];
        final p = 2 * pi * f * t + (k * 0.5);
        padVal += sin(p) * 0.12;
      }

      // Slow space arpeggio
      final arpIdx = ((t / 2.0) % arpFreqs.length).floor();
      final arpF = arpFreqs[arpIdx];
      final arpT = (t % 2.0);
      final arpEnv = exp(-arpT * 2.0);
      final arpVal = sin(2 * pi * arpF * t) * arpEnv * 0.1;

      final mixed = (padVal * lfo + arpVal) * 0.5;
      pcm[i] = (mixed * 32767).toInt().clamp(-32768, 32767);
    }
    return pcm;
  }
}

// ============================================================================
// SFX POOL MANAGER
// ============================================================================

class Sfx {
  static final Map<SfxName, Uint8List> _cache = {};
  static final List<AudioPlayer> _pool = [];
  static int _poolIndex = 0;
  static bool _initialized = false;

  /// Synthesizes all game sounds and initializes the audio pool.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      _cache.addAll(await Isolate.run(_generateSfxCache));

      // Initialize player pool (8 instances for low-latency concurrency)
      for (int i = 0; i < 8; i++) {
        final player = AudioPlayer();
        try {
          await player.setPlayerMode(PlayerMode.lowLatency);
        } catch (_) {}
        _pool.add(player);
      }

      _initialized = true;
    } catch (e) {
      debugPrint("Sfx.init error (continuing without sound): $e");
    }
  }

  /// Plays a pre-rendered sound effect with optional pitch/volume adjustment.
  static void play(SfxName name, {double pitch = 1.0, double volume = 1.0}) {
    if (!SaveService.I.soundEnabled) return;

    try {
      final wav = _cache[name];
      if (wav == null || _pool.isEmpty) return;

      final player = _pool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _pool.length;

      // Reset & Play
      player.stop().then((_) async {
        try {
          if (pitch != 1.0) {
            await player.setPlaybackRate(pitch);
          } else {
            await player.setPlaybackRate(1.0);
          }
          await player.play(
            BytesSource(wav),
            volume: (volume * SaveService.I.sfxVolume).clamp(0.0, 1.0),
          );
        } catch (e) {
          debugPrint("Sfx play error for $name: $e");
        }
      });
    } catch (e) {
      debugPrint("Sfx exception for $name: $e");
    }
  }
}

Map<SfxName, Uint8List> _generateSfxCache() => {
  for (final name in SfxName.values)
    name: createWavHeader(SoundSynth.generateSfx(name)),
};

// ============================================================================
// MUSIC PLAYER MANAGER
// ============================================================================

class Music {
  static AudioPlayer? _player;
  static Uint8List? _musicBytes;
  static bool _isPlaying = false;

  /// Starts the synthesized 16-second ambient space loop.
  static Future<void> start() async {
    if (!SaveService.I.musicEnabled) return;

    try {
      _musicBytes ??= createWavHeader(SoundSynth.generateAmbientMusicLoop());

      if (_player == null) {
        _player = AudioPlayer();
        await _player!.setReleaseMode(ReleaseMode.loop);
      }

      if (!_isPlaying && _musicBytes != null) {
        await _player!.play(
          BytesSource(_musicBytes!),
          volume: SaveService.I.musicVolume,
        );
        _isPlaying = true;
      }
    } catch (e) {
      debugPrint("Music.start exception: $e");
    }
  }

  /// Stops background music playback.
  static Future<void> stop() async {
    try {
      if (_player != null) {
        await _player!.stop();
        _isPlaying = false;
      }
    } catch (e) {
      debugPrint("Music.stop exception: $e");
    }
  }

  /// Updates music state based on user settings.
  static Future<void> updateState() async {
    try {
      if (SaveService.I.musicEnabled) {
        await start();
      } else {
        await stop();
      }
    } catch (e) {
      debugPrint("Music.updateState exception: $e");
    }
  }

  /// Sets volume for background music.
  static Future<void> setVolume(double volume) async {
    try {
      if (_player != null) {
        await _player!.setVolume(volume.clamp(0.0, 1.0));
      }
    } catch (e) {
      debugPrint("Music.setVolume exception: $e");
    }
  }

  /// Applies the persisted volume immediately, including to an active track.
  static Future<void> applySavedVolume() =>
      setVolume(SaveService.I.musicVolume);

  /// Mutes or unmutes music.
  static Future<void> setMuted(bool muted) async {
    try {
      if (muted) {
        await stop();
      } else if (SaveService.I.musicEnabled) {
        await start();
      }
    } catch (e) {
      debugPrint("Music.setMuted exception: $e");
    }
  }
}
