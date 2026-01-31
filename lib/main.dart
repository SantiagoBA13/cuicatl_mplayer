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

// --- PUNTO DE ENTRADA ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicialización del Servicio de Segundo Plano
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.cuicatl.audio',
      androidNotificationChannelName: 'Cuicatl Playback',
      androidNotificationOngoing: true,
      notificationColor: const Color(0xFF8B5CF6),
    );
  } catch (e) {
    debugPrint("⚠️ Error iniciando servicio background: $e");
  }

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
        scaffoldBackgroundColor: const Color(0xFF050505),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E1E2C),
        ),
      ),
      home: const RootHandler(),
    );
  }
}

// --- FONDO ANIMADO (LAVA LAMP) ---
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020205),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Positioned(
                top: -50 + (_controller.value * 60),
                left: -80 + (_controller.value * 40),
                child: Container(
                  width: 500, height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFF4C1D95).withOpacity(0.5), Colors.transparent], radius: 0.6),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Positioned(
                bottom: -100 + (_controller.value * 60),
                right: -80 + (_controller.value * 40),
                child: Container(
                  width: 500, height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFFBE123C).withOpacity(0.4), Colors.transparent], radius: 0.6),
                  ),
                ),
              );
            },
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
          widget.child,
        ],
      ),
    );
  }
}

// --- GESTIÓN DE USUARIO ---
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
    if (_hasName == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
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
  final TextEditingController _nameController = TextEditingController();
  Future<void> _saveName() async {
    if (_nameController.text.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AnimatedBackground(child: MainNavigationController())));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text("Bienvenido a CUICATL", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _nameController, textAlign: TextAlign.center, decoration: InputDecoration(hintText: "¿Cómo te llamas?", filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveName, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)), child: const Text("Comenzar", style: TextStyle(color: Colors.white, fontSize: 18)))
          ],
        ),
      ),
    );
  }
}

// --- NAVEGACIÓN PRINCIPAL ---
class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});
  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _currentQueue = [];
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: _currentIndex == 1 ? HomeScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist) : _pages[_currentIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 75,
              decoration: BoxDecoration(color: const Color(0xFF161622).withOpacity(0.6), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.1))),
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
      ),
    );
  }

  Widget _navBtn(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          if (_audioPlayer.audioSource != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(initialQueue: _currentQueue, initialIndex: _audioPlayer.currentIndex ?? 0, audioPlayer: _audioPlayer, isContinuing: true)));
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona una canción primero")));
          }
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Container(padding: const EdgeInsets.all(12), decoration: isActive ? const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle) : null, child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 28)),
    );
  }
}

// --- PANTALLA DE INICIO (HOME) ---
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
  
  @override
  void initState() {
    super.initState();
    _loadName();
    _initAndroidPermissions(); // Ejecutamos la lógica corregida
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? "Usuario");
  }

  // --- LÓGICA MAESTRA DE PERMISOS (ANDROID 13/14) ---
  Future<void> _initAndroidPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Si es Android 13 (SDK 33) o superior...
      if (androidInfo.version.sdkInt >= 33) {
        debugPrint("📱 Detectado Android 13/14 - Solicitando permisos de AUDIO y NOTIFICACIÓN");
        await [
          Permission.audio,        // El permiso nuevo
          Permission.notification, // Necesario para el mini reproductor
        ].request();
      } else {
        // Android 12 o inferior
        debugPrint("📱 Detectado Android Legacy - Solicitando STORAGE");
        await Permission.storage.request();
      }
    }
    
    // Refresco para que on_audio_query sepa que ya tiene permisos
    setState(() {});
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
          child: Row(children: [_buildPill("Música", 0), _buildPill("Artistas", 1), _buildPill("Playlists", 2)]),
        ),
        const SizedBox(height: 20),
        Expanded(child: _buildHomeTab()),
      ],
    );
  }

  Widget _buildPill(String text, int index) {
    return Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)), child: Text(text, style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)));
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
              _buildCard("Mix Aleatorio", "Sorpresa para tu\nestado de ánimo.", const Color(0xFF34D399), const Color(0xFF059669), Icons.shuffle, _playRandomMix),
              const SizedBox(width: 15),
              _buildCard("Novedades", "Lo más nuevo\nen tu biblioteca.", const Color(0xFFF97316), const Color(0xFFC2410C), Icons.flash_on, _playRandomMix),
              const SizedBox(width: 15),
              _buildCard("Chill Mode", "Relájate y desconecta\ncon sonidos suaves.", const Color(0xFFA855F7), const Color(0xFF7E22CE), Icons.nightlight_round, _playRandomMix),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Todas las canciones", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        _buildMusicList(),
      ],
    );
  }

  Widget _buildMusicList() {
    return FutureBuilder<List<SongModel>>(
      future: _audioQuery.querySongs(sortType: SongSortType.DATE_ADDED, orderType: OrderType.DESC_OR_GREATER, uriType: UriType.EXTERNAL, ignoreCase: true),
      builder: (context, item) {
        if (item.data == null) return const Center(child: CircularProgressIndicator());
        var list = item.data!;
        // Filtro de seguridad
        list = list.where((s) => s.duration != null && s.duration! > 10000).toList();
        
        if (list.isEmpty) return const Center(child: Text("No se encontraron canciones.\nVerifica permisos.", textAlign: TextAlign.center));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: QueryArtworkWidget(id: list[index].id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(width: 50, height: 50, color: Colors.white10, child: const Icon(Icons.music_note)))),
              title: Text(list[index].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(list[index].artist ?? "Desconocido", style: const TextStyle(fontSize: 12, color: Colors.white54)),
              trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF8B5CF6)),
              onTap: () => widget.onPlayRequest(list, index),
            );
          },
        );
      },
    );
  }

  Widget _buildCard(String title, String subtitle, Color c1, Color c2, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(
          children: [
            Positioned(right: -20, bottom: -30, child: Icon(icon, size: 150, color: Colors.black.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 20),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("Reproducir", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.play_arrow, size: 14)]))
              ]),
            )
          ],
        ),
      ),
    );
  }
}

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
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(20), child: Text("Mis Favoritos ❤️", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold))),
        Expanded(
          child: FutureBuilder<List<SongModel>>(
            future: _audioQuery.querySongs(),
            builder: (context, item) {
              if (item.data == null) return const Center(child: CircularProgressIndicator());
              List<SongModel> favSongs = item.data!.where((element) => _favIds.contains(element.id.toString())).toList();
              if (favSongs.isEmpty) return const Center(child: Text("Dale ❤️ a una canción."));
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: favSongs.length,
                itemBuilder: (context, index) => ListTile(
                  leading: QueryArtworkWidget(id: favSongs[index].id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
                  title: Text(favSongs[index].title),
                  subtitle: Text(favSongs[index].artist ?? ""),
                  onTap: () => widget.onPlayRequest(favSongs, index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  void _openSystemEQ() { try { const AndroidIntent(action: 'android.media.action.DISPLAY_AUDIO_EFFECT_CONTROL_PANEL').launch(); } catch (e) {} }
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
      children: [
        const Text("CONFIGURACIÓN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListTile(leading: const Icon(Icons.graphic_eq, color: Color(0xFFEC4899)), title: const Text("Ecualizador del Sistema"), onTap: _openSystemEQ),
        ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Restablecer Usuario"), onTap: () async { final prefs = await SharedPreferences.getInstance(); prefs.remove('userName'); }),
      ],
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final List<SongModel> initialQueue;
  final int initialIndex;
  final AudioPlayer audioPlayer;
  final bool isContinuing;

  const PlayerScreen({super.key, required this.initialQueue, required this.initialIndex, required this.audioPlayer, this.isContinuing = false});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isFav = false;
  Color _adaptiveColor = const Color(0xFF8B5CF6);
  Color _adaptiveBackground = const Color(0xFF0F0F1E);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    if (!widget.isContinuing) _initPlaylist();
    else { _isPlaying = widget.audioPlayer.playing; _updatePalette(); _checkFav(); }

    widget.audioPlayer.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        setState(() => _currentIndex = index);
        if (_pageController.hasClients && _pageController.page?.round() != index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
        _updatePalette(); 
        _checkFav();
      }
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  // --- REPRODUCCIÓN A PRUEBA DE BALAS ---
  Future<void> _initPlaylist() async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: widget.initialQueue.map((song) {
          // ESTA ES LA CLAVE PARA ANDROID 13/14: URI "content://"
          Uri audioUri = Uri.parse("content://media/external/audio/media/${song.id}");
          return AudioSource.uri(
            audioUri,
            tag: MediaItem(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist ?? "Desconocido",
              // Si el arte falla, no rompe la app
              artUri: null, 
            ),
          );
        }).toList(),
      );
      await widget.audioPlayer.setAudioSource(playlist, initialIndex: widget.initialIndex);
      widget.audioPlayer.play();
    } catch (e) { 
      // Si falla, intentamos modo "crudo" (sin metadatos de notificación)
      debugPrint("Error playback: $e. Intentando modo fallback...");
      try {
         final uri = Uri.parse("content://media/external/audio/media/${widget.initialQueue[widget.initialIndex].id}");
         await widget.audioPlayer.setAudioSource(AudioSource.uri(uri));
         widget.audioPlayer.play();
      } catch (e2) {
         debugPrint("Error fatal: $e2");
      }
    }
  }

  Future<void> _updatePalette() async {
    try {
      SongModel song = widget.initialQueue[_currentIndex];
      Uint8List? artworkBytes = await OnAudioQuery().queryArtwork(song.id, ArtworkType.AUDIO, size: 500);
      if (artworkBytes != null) {
        final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(MemoryImage(artworkBytes));
        if (mounted) setState(() { _adaptiveColor = palette.dominantColor?.color ?? const Color(0xFF8B5CF6); _adaptiveBackground = palette.darkMutedColor?.color ?? const Color(0xFF0F0F1E); });
      }
    } catch (e) { debugPrint("Error palette: $e"); }
  }

  Future<void> _checkFav() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];
    setState(() => _isFav = favs.contains(widget.initialQueue[_currentIndex].id.toString()));
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

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.initialQueue[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          AnimatedContainer(duration: const Duration(milliseconds: 800), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_adaptiveBackground.withOpacity(0.8), Colors.black]))),
          Positioned.fill(child: Opacity(opacity: 0.3, child: QueryArtworkWidget(id: currentSong.id, type: ArtworkType.AUDIO, artworkHeight: double.infinity, artworkWidth: double.infinity, size: 1000, artworkFit: BoxFit.cover, nullArtworkWidget: const SizedBox()))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(context)),
                    IconButton(icon: const Icon(Icons.ios_share), onPressed: () {}),
                  ]),
                ),
                const Spacer(),
                
                // CARÁTULA
                SizedBox(
                  height: 340,
                  child: PageView.builder(
                    controller: _pageController, itemCount: widget.initialQueue.length,
                    onPageChanged: (i) => widget.audioPlayer.seek(Duration.zero, index: i),
                    itemBuilder: (context, index) {
                      return Center(
                        child: Container(
                          height: 320, width: 320,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)]),
                          child: ClipRRect(borderRadius: BorderRadius.circular(30), child: QueryArtworkWidget(id: widget.initialQueue[index].id, type: ArtworkType.AUDIO, size: 1000, nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 100)))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                
                // INFO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(currentSong.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(currentSong.artist ?? "Desconocido", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
                        ]),
                      ),
                      IconButton(icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: _isFav ? _adaptiveColor : Colors.white54, size: 28), onPressed: _toggleFav)
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // WAVEFORM
                StreamBuilder<Duration>(
                  stream: widget.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: widget.audioPlayer.durationStream,
                      builder: (context, snapshotDur) {
                        final duration = snapshotDur.data ?? Duration.zero;
                        return Column(
                          children: [
                            WaveformSlider(position: position, duration: duration, color: _adaptiveColor, onSeek: (p) => widget.audioPlayer.seek(p)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text("${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 12, color: Colors.white60)),
                                Text("${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 12, color: Colors.white60)),
                              ]),
                            )
                          ],
                        );
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
                    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 35), onPressed: () => _isPlaying ? widget.audioPlayer.pause() : widget.audioPlayer.play())),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), onPressed: () => widget.audioPlayer.seekToNext()),
                    IconButton(icon: const Icon(Icons.repeat, color: Colors.white54), onPressed: () {}),
                  ],
                ),
                const Spacer(),
                
                DraggableScrollableSheet(
                  initialChildSize: 0.08, minChildSize: 0.08, maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            const Icon(Icons.keyboard_arrow_up, color: Colors.white54),
                            const Text("LETRAS", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                            const SizedBox(height: 30),
                            Padding(padding: const EdgeInsets.all(20), child: Text("Letras próximamente...", style: GoogleFonts.outfit(fontSize: 16, color: Colors.white54))),
                          ],
                        ),
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
        final p = (box.globalToLocal(details.globalPosition).dx / box.size.width).clamp(0.0, 1.0);
        onSeek(Duration(milliseconds: (duration.inMilliseconds * p).round()));
      },
      onTapUp: (details) {
        final box = context.findRenderObject() as RenderBox;
        final p = (box.globalToLocal(details.globalPosition).dx / box.size.width).clamp(0.0, 1.0);
        onSeek(Duration(milliseconds: (duration.inMilliseconds * p).round()));
      },
      child: Container(
        height: 50, width: double.infinity, color: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            final double waveHeight = 10 + (15 * sin(index * 0.5).abs()) + (Random(index).nextInt(10).toDouble());
            final bool isActive = index / barCount <= percentage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4, height: isActive ? waveHeight + 5 : waveHeight,
              decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(5), boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)] : null),
            );
          }),
        ),
      ),
    );
  }
}

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
