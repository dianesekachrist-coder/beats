// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

void main() {
  runApp(const BeatsApp());
}

// ─────────────────────────────────────────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────────────────────────────────────────

class BeatsApp extends StatelessWidget {
  const BeatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080810),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFF9B5DE5),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _loading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _requestAndLoad();
  }

  Future<void> _requestAndLoad() async {
    final storageStatus = await Permission.storage.request();
    final audioStatus = await Permission.audio.request();
    final granted = storageStatus.isGranted || audioStatus.isGranted;

    if (!granted) {
      setState(() {
        _loading = false;
        _permissionDenied = true;
      });
      return;
    }
    await _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _loading = true);
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      setState(() {
        _songs = songs.where((s) => (s.duration ?? 0) > 10000).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              songs: _songs,
              initialIndex: 0,
              overridePath: result.files.first.path!,
              overrideTitle: result.files.first.name,
            ),
          ));
    }
  }

  List<Color> _songColors(int i) {
    const p = [
      [Color(0xFFFF6B35), Color(0xFFFF0844)],
      [Color(0xFF9B5DE5), Color(0xFF00D2FF)],
      [Color(0xFF00B4DB), Color(0xFF0083B0)],
      [Color(0xFFF7971E), Color(0xFFFFD200)],
      [Color(0xFF56AB2F), Color(0xFFA8E063)],
      [Color(0xFFee0979), Color(0xFFff6a00)],
    ];
    return p[i % p.length];
  }

  String _fmtMs(int ms) {
    final s = ms ~/ 1000;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12122A), Color(0xFF080810), Color(0xFF1A0A1F)],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : _permissionDenied
                  ? _buildDenied()
                  : _buildLibrary(),
        ),
      ),
    );
  }

  Widget _buildDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFFFF6B35)),
            const SizedBox(height: 20),
            const Text('Permission requise',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              "Beats a besoin d'accéder à tes fichiers audio.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 28),
            _gradientBtn('Accorder la permission', _requestAndLoad),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _pickFile,
              child: const Text('Choisir un fichier manuellement',
                  style: TextStyle(color: Color(0xFFFF6B35))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _songs.isEmpty ? _buildEmpty() : _buildList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BEATS',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: Colors.white)),
              Text('${_songs.length} morceau${_songs.length > 1 ? 'x' : ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.white38)),
            ],
          ),
          Row(
            children: [
              _iconBtn(Icons.refresh_rounded, _loadSongs),
              const SizedBox(width: 10),
              _iconBtn(Icons.add_rounded, _pickFile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      );

  Widget _buildEmpty() => Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_off_rounded,
                  size: 64, color: Colors.white12),
              const SizedBox(height: 16),
              const Text('Aucun fichier audio trouvé',
                  style: TextStyle(color: Colors.white38, fontSize: 16)),
              const SizedBox(height: 24),
              _gradientBtn('Choisir un fichier', _pickFile),
            ],
          ),
        ),
      );

  Widget _buildList() => Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _songs.length,
          itemBuilder: (ctx, i) {
            final song = _songs[i];
            final colors = _songColors(i);
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PlayerScreen(songs: _songs, initialIndex: i),
                  )),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                            colors: [colors[0], colors[1]],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                      ),
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Icon(Icons.music_note_rounded,
                            color: Colors.white.withOpacity(0.8), size: 24),
                        artworkBorder: BorderRadius.circular(12),
                        artworkFit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 3),
                          Text(song.artist ?? 'Artiste inconnu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.45))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmtMs(song.duration ?? 0),
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.35))),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _gradientBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF0844)]),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PLAYER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PlayerScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int initialIndex;
  final String? overridePath;
  final String? overrideTitle;

  const PlayerScreen({
    super.key,
    required this.songs,
    required this.initialIndex,
    this.overridePath,
    this.overrideTitle,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _player;
  late int _idx;
  bool _isShuffle = false;
  bool _isRepeat = false;

  late AnimationController _vinylCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _player = AudioPlayer();

    _vinylCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.playing)
        _vinylCtrl.repeat();
      else
        _vinylCtrl.stop();
      if (state.processingState == ProcessingState.completed) _nextSong();
      setState(() {});
    });

    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    try {
      if (widget.overridePath != null) {
        await _player.setFilePath(widget.overridePath!);
      } else if (widget.songs.isNotEmpty) {
        final uri = widget.songs[_idx].uri;
        if (uri != null)
          await _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      }
      await _player.play();
    } catch (e) {
      debugPrint('Erreur lecture: $e');
    }
  }

  Future<void> _nextSong() async {
    if (widget.songs.isEmpty) return;
    setState(() {
      _idx = _isShuffle
          ? math.Random().nextInt(widget.songs.length)
          : (_idx + 1) % widget.songs.length;
    });
    await _loadCurrent();
  }

  Future<void> _prevSong() async {
    if (widget.songs.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    setState(() {
      _idx = (_idx - 1 + widget.songs.length) % widget.songs.length;
    });
    await _loadCurrent();
  }

  @override
  void dispose() {
    _player.dispose();
    _vinylCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  SongModel? get _current =>
      widget.songs.isNotEmpty ? widget.songs[_idx] : null;
  String get _title => widget.overrideTitle ?? _current?.title ?? 'Inconnu';
  String get _artist => _current?.artist ?? 'Artiste inconnu';

  List<Color> get _colors {
    const p = [
      [Color(0xFFFF6B35), Color(0xFFFF0844)],
      [Color(0xFF9B5DE5), Color(0xFF00D2FF)],
      [Color(0xFF00B4DB), Color(0xFF0083B0)],
      [Color(0xFFF7971E), Color(0xFFFFD200)],
      [Color(0xFF56AB2F), Color(0xFFA8E063)],
      [Color(0xFFee0979), Color(0xFFff6a00)],
    ];
    return p[_idx % p.length];
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c1 = _colors[0], c2 = _colors[1];
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c1.withOpacity(0.3),
              const Color(0xFF080810),
              c2.withOpacity(0.2)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _vinyl(c1, c2),
                      const SizedBox(height: 32),
                      _songInfo(),
                      const SizedBox(height: 28),
                      _waveform(c1, c2),
                      const SizedBox(height: 12),
                      _progressBar(c1),
                      const SizedBox(height: 28),
                      _controls(c1, c2),
                      const SizedBox(height: 24),
                      _extras(c1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 18),
              ),
            ),
            const Text('EN LECTURE',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Colors.white54)),
            const SizedBox(width: 42),
          ],
        ),
      );

  Widget _vinyl(Color c1, Color c2) => Center(
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (ctx, child) => Transform.scale(
              scale: _player.playing ? _pulseAnim.value : 1.0, child: child),
          child: RotationTransition(
            turns: _vinylCtrl,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c1.withOpacity(0.9),
                    c2.withOpacity(0.7),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF080810)
                  ],
                  stops: const [0.0, 0.28, 0.58, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                      color: c1.withOpacity(0.45),
                      blurRadius: 45,
                      spreadRadius: 6),
                  BoxShadow(
                      color: c2.withOpacity(0.25),
                      blurRadius: 70,
                      spreadRadius: 12),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (double r in [0.4, 0.52, 0.62, 0.72, 0.82])
                    Container(
                      width: 230 * r,
                      height: 230 * r,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.05), width: 1)),
                    ),
                  ClipOval(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: _current != null
                          ? QueryArtworkWidget(
                              id: _current!.id,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Container(
                                  color: const Color(0xFF080810),
                                  child: Icon(Icons.music_note_rounded,
                                      color: c1, size: 32)),
                              artworkFit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFF080810),
                              child: Icon(Icons.music_note_rounded,
                                  color: c1, size: 32)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _songInfo() => Column(
        children: [
          Text(_title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(_artist,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.55),
                  letterSpacing: 0.5)),
        ],
      );

  Widget _waveform(Color c1, Color c2) => AnimatedBuilder(
        animation: _waveCtrl,
        builder: (ctx, _) => SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(30, (i) {
              final phase = _waveCtrl.value * 2 * math.pi;
              final wave = math.sin(phase + i * 0.45) * 0.5 + 0.5;
              final h = _player.playing
                  ? (5 + wave * 28)
                  : (4 + math.sin(i * 0.7) * 3);
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1.4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [c1, c2]),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      );

  Widget _progressBar(Color c1) => StreamBuilder<Duration>(
        stream: _player.positionStream,
        builder: (ctx, posSnap) => StreamBuilder<Duration?>(
          stream: _player.durationStream,
          builder: (ctx, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final prog = dur.inMilliseconds > 0
                ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: c1,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                    overlayColor: c1.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: prog,
                    onChanged: (v) => _player.seek(Duration(
                        milliseconds: (v * dur.inMilliseconds).round())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(pos),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.45))),
                      Text(_fmt(dur),
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.45))),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _controls(Color c1, Color c2) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ctrlBtn(Icons.skip_previous_rounded, 34, _prevSong),
          const SizedBox(width: 22),
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (ctx, snap) {
              final playing = snap.data?.playing ?? false;
              final loading =
                  snap.data?.processingState == ProcessingState.loading ||
                      snap.data?.processingState == ProcessingState.buffering;
              return GestureDetector(
                onTap: () => playing ? _player.pause() : _player.play(),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c1, c2]),
                    boxShadow: [
                      BoxShadow(
                          color: c1.withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 2)
                    ],
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 38,
                          color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(width: 22),
          _ctrlBtn(Icons.skip_next_rounded, 34, _nextSong),
        ],
      );

  Widget _ctrlBtn(IconData icon, double size, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
          child: Icon(icon, size: size, color: Colors.white70),
        ),
      );

  Widget _extras(Color c1) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toggleBtn(Icons.shuffle_rounded, _isShuffle, c1,
              () => setState(() => _isShuffle = !_isShuffle)),
          const SizedBox(width: 20),
          _toggleBtn(Icons.repeat_rounded, _isRepeat, c1, () async {
            setState(() => _isRepeat = !_isRepeat);
            await _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
          }),
          const SizedBox(width: 20),
          SizedBox(
            width: 120,
            child: StreamBuilder<double>(
              stream: _player.volumeStream,
              builder: (ctx, snap) {
                final vol = snap.data ?? 1.0;
                return Row(
                  children: [
                    const Icon(Icons.volume_down_rounded,
                        size: 18, color: Colors.white38),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: c1,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: c1,
                        ),
                        child: Slider(value: vol, onChanged: _player.setVolume),
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded,
                        size: 18, color: Colors.white38),
                  ],
                );
              },
            ),
          ),
        ],
      );

  Widget _toggleBtn(IconData icon, bool active, Color c1, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                active ? c1.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            border: Border.all(
                color: active ? c1.withOpacity(0.5) : Colors.transparent),
          ),
          child: Icon(icon, size: 20, color: active ? c1 : Colors.white38),
        ),
      );
}
