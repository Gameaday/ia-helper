import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Widget for previewing audio files with playback controls
class AudioPreviewWidget extends StatefulWidget {
  final Uint8List audioBytes;
  final String fileName;

  const AudioPreviewWidget({
    super.key,
    required this.audioBytes,
    required this.fileName,
  });

  @override
  State<AudioPreviewWidget> createState() => _AudioPreviewWidgetState();
}

class _AudioPreviewWidgetState extends State<AudioPreviewWidget> {
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  double _volume = 1.0;
  double _speed = 1.0;

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _audioPlayer = AudioPlayer();

      // Set up listeners
      _audioPlayer!.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      // Load audio from bytes
      await _audioPlayer!.setAudioSource(
        _ByteArrayAudioSource(widget.audioBytes),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load audio: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Playback error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _seek(Duration position) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.seek(position);
  }

  Future<void> _skipForward() async {
    if (_audioPlayer == null) return;
    final newPosition = _position + const Duration(seconds: 10);
    await _seek(newPosition > _duration ? _duration : newPosition);
  }

  Future<void> _skipBackward() async {
    if (_audioPlayer == null) return;
    final newPosition = _position - const Duration(seconds: 10);
    await _seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> _setVolume(double volume) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.setVolume(volume);
    setState(() {
      _volume = volume;
    });
  }

  Future<void> _setSpeed(double speed) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.setSpeed(speed);
    setState(() {
      _speed = speed;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading audio...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Audio Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'This audio file may be corrupted or in an unsupported format.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art placeholder / Audio icon
            Builder(
              builder: (context) => Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 100,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // File name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                widget.fileName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Duration display
            Text(
              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Seek bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16.0,
                  ),
                ),
                child: Slider(
                  value: _position.inMilliseconds.toDouble(),
                  min: 0.0,
                  max: _duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _seek(Duration(milliseconds: value.toInt()));
                  },
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Skip backward
                IconButton(
                  icon: Icon(Icons.replay_10, color: Theme.of(context).colorScheme.onSurface),
                  iconSize: 36,
                  onPressed: _skipBackward,
                  tooltip: 'Skip backward 10s',
                ),
                const SizedBox(width: 16),

                // Play/Pause button
                Builder(
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.onInverseSurface,
                      ),
                      iconSize: 48,
                      onPressed: _togglePlayPause,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Skip forward
                IconButton(
                  icon: Icon(Icons.forward_10, color: Theme.of(context).colorScheme.onSurface),
                  iconSize: 36,
                  onPressed: _skipForward,
                  tooltip: 'Skip forward 10s',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Speed control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Speed',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                  Builder(
                    builder: (context) => DropdownButton<double>(
                      value: _speed,
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      items: _speedOptions.map((speed) {
                        return DropdownMenuItem(
                          value: speed,
                          child: Text('${speed}x'),
                        );
                      }).toList(),
                      onChanged: (speed) {
                        if (speed != null) {
                          _setSpeed(speed);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Volume control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Icon(Icons.volume_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: _setVolume,
                      activeColor: Theme.of(context).colorScheme.onSurface,
                      inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  Icon(Icons.volume_up, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom audio source that loads audio from a byte array
class _ByteArrayAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _ByteArrayAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;

    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg', // Generic audio type
    );
  }
}
