import 'dart:ui';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
// CORRECCIÓN AQUÍ: El import correcto es este
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart'; // Para banderas del intent

// --- PUNTO DE ENTRADA ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.cuicatl.audio',
    androidNotificationChannelName: 'Cuicatl Playback',
    androidNotificationOngoing: true,
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
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
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent, // CLAVE: Transparente para que se vea el fondo global
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF34D399),
          surface: Color(0xFF1E1E2C),
        ),
      ),
      home: const RootHandler(),
    );
  }
}

class RootHandler extends StatefulWidget {
  const RootHandler({super.key});
  @override
  State<RootHandler> createState() => _RootHandlerState();
}

class _RootHandlerState extends State<RootHandler> {
  bool? _hasName;
  @override
  void initState() {
    super.initState();
    _checkUserData();
  }
  Future<void> _checkUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _hasName = prefs.containsKey('userName'); });
  }
  @override
  Widget build(BuildContext context) {
    if (_hasName == null) return const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: CircularProgressIndicator()));
    if (_hasName == false) return const OnboardingScreen();
    return const MainNavigationController();
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  Future<void> _saveName() async {
    if (_nameController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationController()));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF0F0F1E)])),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text("Bienvenido a CUICATL", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "¿Cómo te llamas?", filled: true, fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveName,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
                child: const Text("Comenzar", style: TextStyle(color: Colors.white, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- NAVEGACIÓN PRINCIPAL (FIXED) ---
class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});
  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _currentQueue = [];
  
  // Fondo Global
  Color _bg1 = const Color(0xFF0F0F1E);
  Color _bg2 = Colors.black;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist),
      Container(), // Placeholder
      FavoritesScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist),
      const SettingsScreen(),
    ];
    
    _audioPlayer.currentIndexStream.listen((index) {
       if (index != null && _audioPlayer.playing) {
          // Simulación de cambio de ambiente
          setState(() {
             _bg1 = Colors.primaries[Random().nextInt(Colors.primaries.length)].withOpacity(0.3);
          });
       }
    });
  }

  void _playPlaylist(List<SongModel> queue, int index) {
    setState(() => _currentQueue = queue);
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(initialQueue: queue, initialIndex: index, audioPlayer: _audioPlayer),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E), // Fondo base seguro
      extendBody: true, // ESTO ELIMINA EL ESPACIO NEGRO
      body: Stack(
        children: [
          // 1. Fondo Global Animado
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topLeft, radius: 1.3, colors: [_bg1, _bg2])),
          ),
          // 2. Páginas (Transparentes)
          SafeArea(
            bottom: false, // Permitir que el contenido baje hasta el borde
            child: _currentIndex == 1 ? HomeScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist) : _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFF161622).withOpacity(0.6), // Semitransparente
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navBtn(Icons.home_filled, 0),
                _navBtn(Icons.play_circle_fill, 1),
                _navBtn(Icons.favorite, 2),
                _navBtn(Icons.settings, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          if (_audioPlayer.audioSource != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
              initialQueue: _currentQueue, initialIndex: _audioPlayer.currentIndex ?? 0, 
              audioPlayer: _audioPlayer, isContinuing: true)));
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona una canción primero")));
          }
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isActive ? const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle) : null,
        child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 28),
      ),
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final Function(List<SongModel>, int) onPlayRequest;
  const HomeScreen({super.key, required this.audioPlayer, required this.onPlayRequest});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  String _userName = "Usuario";
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadName();
    Permission.storage.request();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? "Usuario");
  }

  Future<void> _playRandomMix() async {
    List<SongModel> songs = await _audioQuery.querySongs();
    if (songs.isNotEmpty) {
      songs.shuffle();
      widget.onPlayRequest(songs, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CUICATL", style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
              IconButton(icon: const Icon(Icons.search, size: 28), onPressed: () => showSearch(context: context, delegate: SongSearchDelegate(_audioQuery, widget.onPlayRequest))),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _buildPill(_userName, 0),
            _buildPill("Música", 1),
            _buildPill("Artistas", 2),
            _buildPill("Playlists", 3),
          ]),
        ),
        const SizedBox(height: 20),
        Expanded(child: _buildBodyContent()),
      ],
    );
  }

  Widget _buildPill(String text, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF8B5CF6) : Colors.white10, borderRadius: BorderRadius.circular(30)),
        child: Text(text, style: GoogleFonts.outfit(color: isSelected ? Colors.white : Colors.white60, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedTab == 0) return _buildHomeTab();
    if (_selectedTab == 1) return _buildMusicTab();
    if (_selectedTab == 2) return _buildArtistsTab();
    if (_selectedTab == 3) return _buildPlaylistsTab();
    return Container();
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Especial para ti", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildCard("Mix Aleatorio", const Color(0xFF34D399), const Color(0xFF059669), Icons.shuffle, _playRandomMix),
              const SizedBox(width: 15),
              _buildCard("Novedades", const Color(0xFFF97316), const Color(0xFFC2410C), Icons.new_releases, _playRandomMix),
              const SizedBox(width: 15),
              _buildCard("Chill Mode", const Color(0xFFA855F7), const Color(0xFF7E22CE), Icons.nights_stay, _playRandomMix),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Escuchado recientemente", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        FutureBuilder<List<SongModel>>(
          future: _audioQuery.querySongs(sortType: SongSortType.DATE_ADDED, orderType: OrderType.DESC_OR_GREATER),
          builder: (context, item) {
            if (item.data == null) return const SizedBox();
            return Column(children: item.data!.take(5).map((e) => _songTile(e, item.data!, item.data!.indexOf(e))).toList());
          },
        )
      ],
    );
  }

  Widget _buildMusicTab() {
    return FutureBuilder<List<SongModel>>(
      future: _audioQuery.querySongs(sortType: SongSortType.TITLE, orderType: OrderType.ASC_OR_SMALLER, uriType: UriType.EXTERNAL, ignoreCase: true),
      builder: (context, item) {
        if (item.data == null) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: item.data!.length,
          itemBuilder: (context, index) => _songTile(item.data![index], item.data!, index),
        );
      },
    );
  }

  Widget _buildArtistsTab() {
    return FutureBuilder<List<ArtistModel>>(
      future: _audioQuery.queryArtists(sortType: ArtistSortType.ARTIST, orderType: OrderType.ASC_OR_SMALLER),
      builder: (context, item) {
        if (item.data == null) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120), itemCount: item.data!.length,
          itemBuilder: (context, index) => ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person)),
            title: Text(item.data![index].artist, maxLines: 1),
            subtitle: Text("${item.data![index].numberOfTracks} canciones"),
            onTap: () async {
                List<SongModel> songs = await _audioQuery.queryAudiosFrom(AudiosFromType.ARTIST_ID, item.data![index].id);
                widget.onPlayRequest(songs, 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab() {
    return Center(child: Text("Crea tus playlists aquí", style: GoogleFonts.outfit(color: Colors.white54)));
  }

  Widget _buildCard(String title, Color c1, Color c2, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(
          children: [
            Positioned(right: -20, bottom: -30, child: Icon(icon, size: 150, color: Colors.black.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5),
                const Text("Selección especial basada\nen tu biblioteca.", style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 15),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("Reproducir", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.play_arrow, size: 14)]))
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _songTile(SongModel song, List<SongModel> fullList, int index) {
    return ListTile(
      leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(width: 50, height: 50, color: Colors.white10, child: const Icon(Icons.music_note)))),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(song.artist ?? "Desconocido", style: const TextStyle(fontSize: 12, color: Colors.white54)),
      trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF8B5CF6)),
      onTap: () => widget.onPlayRequest(fullList, index),
    );
  }
}

// --- BUSCADOR ---
class SongSearchDelegate extends SearchDelegate {
  final OnAudioQuery audioQuery;
  final Function(List<SongModel>, int) onPlay;
  SongSearchDelegate(this.audioQuery, this.onPlay);

  @override
  ThemeData appBarTheme(BuildContext context) => ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0F0F1E), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E2C)));
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<SongModel>>(
      future: audioQuery.querySongs(),
      builder: (context, item) {
        if (!item.hasData) return const Center(child: CircularProgressIndicator());
        final results = item.data!.where((s) => s.title.toLowerCase().contains(query.toLowerCase())).toList();
        return ListView.builder(
          itemCount: results.length, itemBuilder: (context, index) {
            return ListTile(title: Text(results[index].title), subtitle: Text(results[index].artist ?? ""), onTap: () { close(context, null); onPlay(results, index); });
          },
        );
      },
    );
  }
}

// --- FAVORITOS (Transparente) ---
class FavoritesScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final Function(List<SongModel>, int) onPlayRequest;
  const FavoritesScreen({super.key, required this.audioPlayer, required this.onPlayRequest});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> _favIds = [];
  final OnAudioQuery _audioQuery = OnAudioQuery();
  @override
  void initState() { super.initState(); _loadFavs(); }
  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _favIds = prefs.getStringList('favorites') ?? []);
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(20), child: Text("Mis Favoritos ❤️", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold))),
          Expanded(
            child: FutureBuilder<List<SongModel>>(
              future: _audioQuery.querySongs(),
              builder: (context, item) {
                if (item.data == null) return const Center(child: CircularProgressIndicator());
                List<SongModel> favSongs = item.data!.where((element) => _favIds.contains(element.id.toString())).toList();
                if (favSongs.isEmpty) return const Center(child: Text("Dale ❤️ a una canción para verla aquí."));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: favSongs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: QueryArtworkWidget(id: favSongs[index].id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
                      title: Text(favSongs[index].title),
                      subtitle: Text(favSongs[index].artist ?? ""),
                      trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white24), onPressed: () async {
                         final prefs = await SharedPreferences.getInstance();
                         _favIds.remove(favSongs[index].id.toString());
                         await prefs.setStringList('favorites', _favIds);
                         setState(() {});
                      }),
                      onTap: () => widget.onPlayRequest(favSongs, index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- CONFIGURACIÓN ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hqAudio = false;
  bool _crossfade = false;
  bool _amoled = false;

  @override
  void initState() { super.initState(); _loadSettings(); }
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _hqAudio = prefs.getBool('hqAudio') ?? false; _crossfade = prefs.getBool('crossfade') ?? false; _amoled = prefs.getBool('amoled') ?? false; });
  }
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance(); await prefs.setBool(key, value);
    setState(() { if(key == 'hqAudio') _hqAudio = value; if(key == 'crossfade') _crossfade = value; if(key == 'amoled') _amoled = value; });
  }
  
  void _openSystemEQ() {
    try {
      const AndroidIntent intent = AndroidIntent(action: 'android.media.action.DISPLAY_AUDIO_EFFECT_CONTROL_PANEL');
      intent.launch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se encontró Ecualizador en tu sistema")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
      children: [
        const Text("CONFIGURACIÓN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text("AUDIO PRO", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
        SwitchListTile(value: _hqAudio, onChanged: (v) => _saveSetting('hqAudio', v), title: const Text("Forzar Alta Calidad"), subtitle: const Text("Intenta usar drivers Hi-Res"), activeColor: const Color(0xFF8B5CF6)),
        SwitchListTile(value: _crossfade, onChanged: (v) => _saveSetting('crossfade', v), title: const Text("Crossfade"), subtitle: const Text("Mezcla suave entre canciones"), activeColor: const Color(0xFF8B5CF6)),
        ListTile(
          leading: const Icon(Icons.graphic_eq, color: Color(0xFF34D399), size: 30),
          title: const Text("Ecualizador Profesional"),
          subtitle: const Text("Abrir DSP del Sistema"),
          onTap: _openSystemEQ,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(color: Colors.white12),
        const Text("APARIENCIA", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
        SwitchListTile(value: _amoled, onChanged: (v) => _saveSetting('amoled', v), title: const Text("Tema AMOLED Puro"), activeColor: const Color(0xFF8B5CF6)),
        const Divider(color: Colors.white12),
        ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Restablecer Usuario"), onTap: () async {
          final prefs = await SharedPreferences.getInstance(); prefs.remove('userName');
          if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        }),
      ],
    );
  }
}

// --- REPRODUCTOR PREMIUM (CON NOTIFICACIONES REALES) ---
class PlayerScreen extends StatefulWidget {
  final List<SongModel> initialQueue;
  final int initialIndex;
  final AudioPlayer audioPlayer;
  final bool isContinuing;

  const PlayerScreen({super.key, required this.initialQueue, required this.initialIndex, required this.audioPlayer, this.isContinuing = false});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isFav = false;
  
  Color _adaptiveColor = const Color(0xFF8B5CF6);
  Color _adaptiveBackground = const Color(0xFF2E1065);
  
  Stream<Duration>? _positionStream;
  Stream<Duration?>? _durationStream;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

    _positionStream = widget.audioPlayer.positionStream;
    _durationStream = widget.audioPlayer.durationStream;

    if (!widget.isContinuing) _initPlaylist();
    else {
      _isPlaying = widget.audioPlayer.playing;
      _updatePalette(); 
    }

    widget.audioPlayer.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        setState(() => _currentIndex = index);
        if (_pageController.hasClients && _pageController.page?.round() != index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
        _updatePalette(); 
      }
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if(state.playing) _waveController.repeat(); else _waveController.stop();
    });
  }

  Future<void> _initPlaylist() async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: widget.initialQueue.map((song) {
          return AudioSource.uri(
            Uri.parse(song.uri!),
            tag: MediaItem(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist ?? "Desconocido",
              artUri: null, 
            ),
          );
        }).toList(),
      );
      
      await widget.audioPlayer.setAudioSource(playlist, initialIndex: widget.initialIndex);
      widget.audioPlayer.play();
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _updatePalette() async {
    try {
      SongModel song = widget.initialQueue[_currentIndex];
      Uint8List? artworkBytes = await OnAudioQuery().queryArtwork(song.id, ArtworkType.AUDIO, size: 500);
      if (artworkBytes != null) {
        final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(MemoryImage(artworkBytes));
        if (mounted) {
          setState(() {
            _adaptiveColor = palette.dominantColor?.color ?? const Color(0xFF8B5CF6);
            _adaptiveBackground = palette.darkMutedColor?.color ?? const Color(0xFF0F0F1E);
          });
        }
      }
    } catch (e) { debugPrint("Error palette: $e"); }
  }

  Future<void> _toggleFav() async {
    final song = widget.initialQueue[_currentIndex];
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];
    String id = song.id.toString();
    if (favs.contains(id)) { favs.remove(id); setState(() => _isFav = false); }
    else { favs.add(id); setState(() => _isFav = true); }
    await prefs.setStringList('favorites', favs);
  }
  
  void _showTimerDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E2C),
      title: const Text("Temporizador"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
         ListTile(title: const Text("15 Minutos"), onTap: (){ Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se detendrá en 15 min"))); }),
         ListTile(title: const Text("30 Minutos"), onTap: (){ Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Se detendrá en 30 min"))); }),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialQueue.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final currentSong = widget.initialQueue[_currentIndex];

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_adaptiveBackground.withOpacity(0.8), const Color(0xFF050505)]))
          ),
           Positioned.fill(child: RepaintBoundary(child: Opacity(opacity: 0.4, child: QueryArtworkWidget(id: currentSong.id, type: ArtworkType.AUDIO, artworkHeight: MediaQuery.of(context).size.height, artworkWidth: MediaQuery.of(context).size.height, size: 1000, artworkFit: BoxFit.cover, nullArtworkWidget: const SizedBox())))),
           BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassBtn(Icons.keyboard_arrow_down, () => Navigator.pop(context)),
                      Text("REPRODUCIENDO", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, letterSpacing: 2)),
                      PopupMenuButton<String>(
                        icon: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.more_vert, size: 20)),
                        color: const Color(0xFF1E1E2C),
                        onSelected: (v) {
                          if (v == 'timer') _showTimerDialog();
                          if (v == 'eq') { try { const AndroidIntent(action: 'android.media.action.DISPLAY_AUDIO_EFFECT_CONTROL_PANEL').launch(); } catch(e){} }
                        },
                        itemBuilder: (c) => [
                          const PopupMenuItem(value: 'timer', child: Text("Temporizador 🌙")),
                          const PopupMenuItem(value: 'eq', child: Text("Ecualizador 🎚️")),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1), 
                SizedBox(
                  height: 340,
                  child: PageView.builder(
                    controller: _pageController, itemCount: widget.initialQueue.length,
                    onPageChanged: (index) { widget.audioPlayer.seek(Duration.zero, index: index); },
                    itemBuilder: (context, index) {
                      return Center(
                        child: Container(
                          height: 320, width: 320,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))]),
                          child: ClipRRect(borderRadius: BorderRadius.circular(30), child: QueryArtworkWidget(id: widget.initialQueue[index].id, type: ArtworkType.AUDIO, artworkHeight: 320, artworkWidth: 320, size: 1000, quality: 100, nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 100, color: Colors.white24)))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(currentSong.artist ?? "Desconocido", style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70)),
                          const SizedBox(height: 5),
                          Text(currentSong.title, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      IconButton(icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: _isFav ? _adaptiveColor : Colors.white54, size: 30), onPressed: _toggleFav)
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                StreamBuilder<Duration>(
                  stream: _positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: _durationStream,
                      builder: (context, snapshotDur) {
                        final duration = snapshotDur.data ?? Duration.zero;
                        return Column(children: [
                            WaveformSlider(position: position, duration: duration, color: _adaptiveColor, onSeek: (p) => widget.audioPlayer.seek(p)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(_formatDuration(position), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                                  Text(_formatDuration(duration), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                              ]),
                            )
                        ]);
                      }
                    );
                  }
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.shuffle, color: Colors.white54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white), onPressed: () => widget.audioPlayer.seekToPrevious()),
                    GestureDetector(
                      onTap: () => _isPlaying ? widget.audioPlayer.pause() : widget.audioPlayer.play(),
                      child: Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(color: _adaptiveColor.withOpacity(0.8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: _adaptiveColor.withOpacity(0.4), blurRadius: 20)]),
                        child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), onPressed: () => widget.audioPlayer.seekToNext()),
                    IconButton(icon: const Icon(Icons.repeat, color: Colors.white54), onPressed: () {}),
                  ],
                ),
                const Spacer(flex: 2),
                DraggableScrollableSheet(
                  initialChildSize: 0.03, minChildSize: 0.03, maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: const Column(children: [SizedBox(height: 10), Icon(Icons.keyboard_arrow_up), Text("LETRAS", style: TextStyle(letterSpacing: 2)), SizedBox(height: 500, child: Center(child: Text("Busca letras...")))]),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 20)),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}

class WaveformSlider extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;
  final Color color;

  const WaveformSlider({super.key, required this.position, required this.duration, required this.onSeek, required this.color});

  @override
  Widget build(BuildContext context) {
    const int barCount = 35; 
    final double percentage = duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        onSeek(Duration(milliseconds: (duration.inMilliseconds * (box.globalToLocal(details.globalPosition).dx / box.size.width).clamp(0.0, 1.0)).round()));
      },
      onTapUp: (details) {
        final box = context.findRenderObject() as RenderBox;
        onSeek(Duration(milliseconds: (duration.inMilliseconds * (box.globalToLocal(details.globalPosition).dx / box.size.width).clamp(0.0, 1.0)).round()));
      },
      child: Container(
        height: 50, width: double.infinity, color: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            final double waveHeight = 10 + (15 * sin(index * 0.5).abs()) + (Random(index).nextInt(15).toDouble());
            final bool isActive = index / barCount <= percentage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4, height: isActive ? waveHeight + 5 : waveHeight,
              decoration: BoxDecoration(color: isActive ? color : Colors.white24, borderRadius: BorderRadius.circular(5), boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)] : null),
            );
          }),
        ),
      ),
    );
  }
}
