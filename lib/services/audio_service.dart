import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Original synthesized tones and ambient pads. No external audio is shipped.
class GameAudioService {
  GameAudioService() {
    _effects = AudioPlayer(playerId: 'orbit-effects');
    _music = AudioPlayer(playerId: 'orbit-music');
  }

  late final AudioPlayer _effects;
  late final AudioPlayer _music;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  int _musicZone = -1;
  bool _musicFever = false;
  bool _disposed = false;

  Future<void> setPreferences({required bool sound, required bool music}) async {
    _soundEnabled = sound;
    _musicEnabled = music;
    if (!music) {
      await _safely(() => _music.pause());
    } else if (_musicZone >= 0) {
      await startMusic(_musicZone, fever: _musicFever);
    }
  }

  Future<void> playLaunch({int combo = 0}) => _playTone(
        startHz: (360 + math.min(400, combo * 22)).toDouble(),
        endHz: (620 + math.min(520, combo * 28)).toDouble(),
        duration: 0.14,
        waveform: 0,
        volume: 0.34,
      );

  Future<void> playLanding({required bool perfect, required int combo}) => _playTone(
        startHz: ((perfect ? 640 : 460) + math.min(500, combo * 26)).toDouble(),
        endHz: ((perfect ? 1120 : 720) + math.min(600, combo * 30)).toDouble(),
        duration: perfect ? 0.25 : 0.18,
        waveform: 1,
        volume: perfect ? 0.48 : 0.38,
      );

  Future<void> playCoin() => _playTone(
        startHz: 910,
        endHz: 1330,
        duration: 0.1,
        waveform: 0,
        volume: 0.23,
      );

  Future<void> playDeath() => _playTone(
        startHz: 360,
        endHz: 105,
        duration: 0.38,
        waveform: 2,
        volume: 0.4,
      );

  Future<void> startMusic(int zone, {bool fever = false}) async {
    _musicZone = zone;
    _musicFever = fever;
    if (!_musicEnabled || _disposed) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.2);
      await _music.play(BytesSource(_ambientPad(zone, fever: fever), mimeType: 'audio/wav'));
    } catch (_) {
      // Audio is a presentation layer; device codecs/focus failures must not
      // prevent an offline run from continuing.
    }
  }

  Future<void> setFeverLayer(bool fever) async {
    if (_musicZone < 0 || _musicFever == fever) return;
    await startMusic(_musicZone, fever: fever);
  }

  Future<void> _playTone({
    required double startHz,
    required double endHz,
    required double duration,
    required int waveform,
    required double volume,
  }) async {
    if (!_soundEnabled || _disposed) return;
    try {
      await _effects.setVolume(volume);
      await _effects.play(BytesSource(
        _tone(startHz, endHz, duration, waveform: waveform),
        mimeType: 'audio/wav',
      ));
    } catch (_) {
      // Never surface audio plugin/codec failures as game failures.
    }
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Platform audio can be interrupted by calls, alarms, and audio focus.
    }
  }

  Uint8List _tone(double from, double to, double seconds, {required int waveform}) {
    const int sampleRate = 22050;
    final int sampleCount = (sampleRate * seconds).round();
    final Int16List samples = Int16List(sampleCount);
    double phase = 0;
    for (int i = 0; i < sampleCount; i++) {
      final double progress = i / sampleCount;
      final double frequency = from + (to - from) * progress;
      phase += 2 * math.pi * frequency / sampleRate;
      final double envelope = math.sin(math.pi * progress).clamp(0.0, 1.0).toDouble();
      final double fundamental = switch (waveform) {
        1 => math.sin(phase) * 0.75 + math.sin(phase * 2.01) * 0.18,
        2 => math.sin(phase) * 0.82 + math.sin(phase * 0.5) * 0.14,
        _ => math.sin(phase),
      };
      samples[i] = (fundamental * envelope * 12000).round().clamp(-32768, 32767).toInt();
    }
    return _wave(samples, sampleRate);
  }

  Uint8List _ambientPad(int zone, {required bool fever}) {
    const int sampleRate = 22050;
    const int seconds = 8;
    final int count = sampleRate * seconds;
    final Int16List samples = Int16List(count);
    const List<List<double>> chords = <List<double>>[
      <double>[110, 164.81, 220],
      <double>[123.47, 185, 246.94],
      <double>[98, 146.83, 196],
      <double>[130.81, 196, 261.63],
      <double>[116.54, 174.61, 233.08],
      <double>[146.83, 220, 293.66],
    ];
    final List<double> notes = chords[zone % chords.length];
    for (int i = 0; i < count; i++) {
      final double time = i / sampleRate;
      final double swell = 0.58 + 0.22 * math.sin(2 * math.pi * time / seconds);
      double value = 0;
      for (int noteIndex = 0; noteIndex < notes.length; noteIndex++) {
        final double note = notes[noteIndex] * (fever && noteIndex == 2 ? 1.5 : 1);
        value += math.sin(2 * math.pi * note * time + noteIndex * 0.7) /
            (notes.length * 1.6);
      }
      final double bell = (math.sin(2 * math.pi * notes[2] * 2 * time) *
              math.pow(math.max(0, math.sin(math.pi * time / 2)), 3) *
              (fever ? 0.1 : 0.045))
          .toDouble();
      samples[i] = ((value + bell) * swell * 2800).round().clamp(-32768, 32767).toInt();
    }
    return _wave(samples, sampleRate);
  }

  Uint8List _wave(Int16List samples, int sampleRate) {
    final int dataLength = samples.length * 2;
    final ByteData data = ByteData(44 + dataLength);
    void writeAscii(int offset, String value) {
      for (int i = 0; i < value.length; i++) {
        data.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, dataLength, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      data.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }

  Future<void> pause() async {
    await _safely(() => _music.pause());
    await _safely(() => _effects.pause());
  }

  Future<void> resume() async {
    if (_musicEnabled && _musicZone >= 0) await startMusic(_musicZone, fever: _musicFever);
  }

  Future<void> dispose() async {
    _disposed = true;
    await _safely(() => _music.dispose());
    await _safely(() => _effects.dispose());
  }
}
