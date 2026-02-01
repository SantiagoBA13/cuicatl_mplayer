import 'dart:ui';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.cuicatl.audio',
      androidNotificationChannelName: 'Cuicatl Playback',
      androidNotificationOngoing: true,
      notificationColor: const Color(0xFF8B5CF6),
    );
  } catch (e) {
    debugPrint("Error iniciando background service: $e");
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const CuicatlApp());
}

class CuicatlApp extends StatelessWidget {
  const CuicatlApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuicatl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF8B5CF6), secondary: Color(0xFFEC4899), surface: Color(0xFF1E1E2C)),
        useMaterial3: true,
      ),
      home: const RootHandler(),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020205),
      body: Stack(
        children: [
          AnimatedBuilder(animation: _c, builder: (_,__) => Positioned(top: -50+(_c.value*60), left: -80+(_c.value*40), child: _blob(const Color(0xFF4C1D95)))),
          AnimatedBuilder(animation: _c, builder: (_,__) => Positioned(bottom: -100+(_c.value*60), right: -80+(_c.value*40), child: _blob(const Color(0xFFBE123C)))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
          widget.child,
        ],
      ),
    );
  }
  Widget _blob(Color c) => Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c.withOpacity(0.5), Colors.transparent], radius: 0.6)));
}

class RootHandler extends StatefulWidget {
  const RootHandler({super.key});
  @override
  State<RootHandler> createState() => _RootHandlerState();
}

class _RootHandlerState extends State<RootHandler> {
  bool? _hasName;
  @override
  void initState() { super.initState(); _checkData(); }
  Future<void> _checkData() async { final p = await SharedPreferences.getInstance(); setState(() => _hasName = p.containsKey('userName')); }
  @override
  Widget build(BuildContext context) {
    if (_hasName == null) return const Scaffold(backgroundColor: Colors.black);
    if (_hasName == false) return const OnboardingScreen();
    return const AnimatedBackground(child: MainNavigationController());
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.music_note_rounded, size: 80, color: Colors.white),
        const SizedBox(height: 20),
        Text("Bienvenido a CUICATL", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        TextField(controller: _c, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "¿Tu nombre?", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)))),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () async {
          if(_c.text.isNotEmpty) {
            (await SharedPreferences.getInstance()).setString('userName', _c.text);
            if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AnimatedBackground(child: MainNavigationController())));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)), child: const Text("Comenzar", style: TextStyle(color: Colors.white)))
      ])),
    );
  }
}

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});
  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  int _idx = 0;
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _queue = [];

  void _play(List<SongModel> q, int i) {
    setState(() => _queue = q);
    Navigator.push(context, MaterialPageRoute(builder: (_)=>PlayerScreen(queue: q, idx: i, player: _player)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(bottom: false, child: _idx == 1 ? HomeScreen(player: _player, onPlay: _play) : [_idx == 0 ? HomeScreen(player: _player, onPlay: _play) : Container(), Container(), FavoritesScreen(player: _player, onPlay: _play), const SettingsScreen()][_idx]),
      bottomNavigationBar: Padding(padding: const EdgeInsets.fromLTRB(20,0,20,30), child: ClipRRect(borderRadius: BorderRadius.circular(40), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), child: Container(height: 75, color: const Color(0xFF161622).withOpacity(0.6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _btn(Icons.home_filled, 0), _btn(Icons.play_circle_fill, 1), _btn(Icons.favorite, 2), _btn(Icons.settings, 3)
      ]))))),
    );
  }
  Widget _btn(IconData i, int x) => GestureDetector(onTap: () {
    if(x==1) {
      if(_player.audioSource!=null) Navigator.push(context, MaterialPageRoute(builder: (_)=>PlayerScreen(queue: _queue, idx: 0, player: _player, continuing: true)));
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona una canción")));
    } else setState(() => _idx = x);
  }, child: Container(padding: const EdgeInsets.all(12), decoration: _idx==x ? const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle) : null, child: Icon(i, color: _idx==x ? Colors.white : Colors.white54, size: 28)));
}

class HomeScreen extends StatefulWidget {
  final AudioPlayer player;
  final Function(List<SongModel>, int) onPlay;
  const HomeScreen({super.key, required this.player, required this.onPlay});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  String _userName = "Usuario";

  @override
  void initState() { super.initState(); _initPerms(); _loadName(); }
  Future<void> _loadName() async { setState(() => _userName = (await SharedPreferences.getInstance()).getString('userName') ?? "Usuario"); }

  Future<void> _initPerms() async {
    if(Platform.isAndroid) {
      final v = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if(v >= 33) await [Permission.audio, Permission.notification].request();
      else await Permission.storage.request();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("CUICATL", style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
          IconButton(icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: SongSearchDelegate(_audioQuery, widget.onPlay)))
        ])),
        Expanded(child: FutureBuilder<List<SongModel>>(
          future: _audioQuery.querySongs(sortType: SongSortType.DATE_ADDED, orderType: OrderType.DESC_OR_GREATER, uriType: UriType.EXTERNAL, ignoreCase: true),
          builder: (context, item) {
            if(item.data == null) return const Center(child: CircularProgressIndicator());
            var songs = item.data!.where((s) => s.duration != null && s.duration! > 10000).toList();
            if(songs.isEmpty) return const Center(child: Text("Sin canciones o permisos."));
            return ListView.builder(itemCount: songs.length, itemBuilder: (ctx, i) => ListTile(
              leading: QueryArtworkWidget(id: songs[i].id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
              title: Text(songs[i].title, maxLines: 1), subtitle: Text(songs[i].artist ?? "<unknown>"),
              onTap: () => widget.onPlay(songs, i),
            ));
          },
        )),
      ],
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  final AudioPlayer player;
  final Function(List<SongModel>, int) onPlay; 
  const FavoritesScreen({super.key, required this.player, required this.onPlay});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favs = [];
  final _query = OnAudioQuery();
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { setState(() => _favs = (await SharedPreferences.getInstance()).getStringList('favorites') ?? []); }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Text("Favoritos ❤️", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold))),
      Expanded(child: FutureBuilder<List<SongModel>>(
        future: _query.querySongs(),
        builder: (ctx, snap) {
          if(!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!.where((s) => _favs.contains(s.id.toString())).toList();
          if(list.isEmpty) return const Center(child: Text("Aún no tienes favoritos"));
          return ListView.builder(itemCount: list.length, itemBuilder: (c, i) => ListTile(
            leading: QueryArtworkWidget(id: list[i].id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
            title: Text(list[i].title), subtitle: Text(list[i].artist ?? ""),
            onTap: () => widget.onPlay(list, i),
          ));
        },
      ))
    ]);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text("CONFIGURACIÓN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      ListTile(leading: const Icon(Icons.graphic_eq), title: const Text("Ecualizador"), onTap: () { try { const AndroidIntent(action: 'android.media.action.DISPLAY_AUDIO_EFFECT_CONTROL_PANEL').launch(); } catch(e){} }),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Reiniciar App"), onTap: () async { (await SharedPreferences.getInstance()).remove('userName'); })
    ]);
  }
}

class PlayerScreen extends StatefulWidget {
  final List<SongModel> queue;
  final int idx;
  final AudioPlayer player;
  final bool continuing;
  const PlayerScreen({super.key, required this.queue, required this.idx, required this.player, this.continuing = false});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _idx = 0;
  bool _playing = false;
  bool _fav = false;
  Color _color = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _idx = widget.idx;
    if(!widget.continuing) _initPlaylist();
    else { _playing = widget.player.playing; _upd(); }
    
    widget.player.currentIndexStream.listen((i) { if(i!=null && mounted) { setState(() => _idx = i); _upd(); } });
    widget.player.playerStateStream.listen((s) { if(mounted) setState(() => _playing = s.playing); });
  }

  // --- REPRODUCCIÓN CORREGIDA Y ROBUSTA ---
  Future<void> _initPlaylist() async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: widget.queue.map((song) {
          // Validamos que la URI exista, si no, intentamos construirla
          Uri uri;
          if (song.uri != null && song.uri!.isNotEmpty) {
             uri = Uri.parse(song.uri!);
          } else {
             uri = Uri.parse("content://media/external/audio/media/${song.id}");
          }

          return AudioSource.uri(
            uri,
            tag: MediaItem(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist ?? "Desconocido",
            ),
          );
        }).toList(),
      );

      await widget.player.setAudioSource(playlist, initialIndex: _idx);
      widget.player.play();
    } catch (e) {
      debugPrint("Error playback con Metadata: $e");
      // Fallback: Intento simple si falla el servicio
      try {
         final u = Uri.parse("content://media/external/audio/media/${widget.queue[_idx].id}");
         await widget.player.setAudioSource(AudioSource.uri(u));
         widget.player.play();
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reproduciendo en modo básico")));
      } catch (e2) {
         if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al reproducir: $e2"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _upd() async {
    final s = widget.queue[_idx];
    final p = await PaletteGenerator.fromImageProvider(MemoryImage((await OnAudioQuery().queryArtwork(s.id, ArtworkType.AUDIO, size: 500))!));
    if(mounted) setState(() => _color = p.dominantColor?.color ?? const Color(0xFF8B5CF6));
    final prefs = await SharedPreferences.getInstance();
    setState(() => _fav = (prefs.getStringList('favorites') ?? []).contains(s.id.toString()));
  }

  Future<void> _togFav() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> l = prefs.getStringList('favorites') ?? [];
    String id = widget.queue[_idx].id.toString();
    if(l.contains(id)) { l.remove(id); setState(()=>_fav=false); } else { l.add(id); setState(()=>_fav=true); }
    prefs.setStringList('favorites', l);
  }

  @override
  Widget build(BuildContext context) {
    if(widget.queue.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final s = widget.queue[_idx];
    
    return Scaffold(
      body: Stack(children: [
        AnimatedContainer(duration: const Duration(seconds: 1), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_color.withOpacity(0.6), Colors.black]))),
        SafeArea(child: Column(children: [
          Row(children: [IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: ()=>Navigator.pop(context))]),
          const Spacer(),
          Container(height: 320, width: 320, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black54)]), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: QueryArtworkWidget(id: s.id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note, size: 100)))),
          const SizedBox(height: 40),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1), Text(s.artist??"", style: const TextStyle(color: Colors.white60))])),
            IconButton(icon: Icon(_fav ? Icons.favorite : Icons.favorite_border, color: _fav ? _color : Colors.white), onPressed: _togFav)
          ])),
          const SizedBox(height: 20),
          StreamBuilder<Duration>(stream: widget.player.positionStream, builder: (_, snap) {
            final pos = snap.data ?? Duration.zero;
            return StreamBuilder<Duration?>(stream: widget.player.durationStream, builder: (_, dSnap) {
              final dur = dSnap.data ?? Duration.zero;
              return Column(children: [
                Slider(activeColor: _color, value: pos.inSeconds.toDouble().clamp(0, dur.inSeconds.toDouble()), max: dur.inSeconds.toDouble(), onChanged: (v)=>widget.player.seek(Duration(seconds: v.toInt()))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${pos.inMinutes}:${(pos.inSeconds%60).toString().padLeft(2,'0')}"), Text("${dur.inMinutes}:${(dur.inSeconds%60).toString().padLeft(2,'0')}")]))
              ]);
            });
          }),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: widget.player.seekToPrevious),
            Container(margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: IconButton(icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 40), onPressed: () => _playing ? widget.player.pause() : widget.player.play())),
            IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: widget.player.seekToNext),
          ]),
          const Spacer(),
        ]))
      ]),
    );
  }
}

class SongSearchDelegate extends SearchDelegate {
  final OnAudioQuery audioQuery;
  final Function(List<SongModel>, int) onPlay;
  SongSearchDelegate(this.audioQuery, this.onPlay);

  @override
  ThemeData appBarTheme(BuildContext context) => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E2C)),
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        )
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text("Escribe para buscar canciones…"));
    }

    return FutureBuilder<List<SongModel>>(
      future: audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final q = query.toLowerCase().trim();
        final all = snap.data ?? [];
        final filtered = all.where((s) {
          final title = (s.title).toLowerCase();
          final artist = (s.artist ?? "").toLowerCase();
          return title.contains(q) || artist.contains(q);
        }).toList();

        if (filtered.isEmpty) return const Center(child: Text("Sin resultados"));

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final song = filtered[index];
            return ListTile(
              leading: QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                nullArtworkWidget: const Icon(Icons.music_note),
              ),
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist ?? "Desconocido", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                close(context, null);
                onPlay(filtered, index);
              },
            );
          },
        );
      },
    );
  }
}
