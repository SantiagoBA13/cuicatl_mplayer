import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// --- PUNTO DE ENTRADA ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuración de pantalla completa
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CuicatlApp());
}

// --- CONFIGURACIÓN APP ---
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
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
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

// --- GESTOR DE ESTADO ---
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
    if (_hasName == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_hasName == false) return const OnboardingScreen();
    return const MainNavigationController();
  }
}

// --- BIENVENIDA ---
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

// --- CONTROLADOR DE NAVEGACIÓN ---
class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});
  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Mantenemos una lista global para saber qué se está reproduciendo
  List<SongModel> _currentQueue = [];
  int _currentSongIndex = -1;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        audioPlayer: _audioPlayer, 
        onPlayRequest: _playPlaylist
      ),
      Container(), 
      FavoritesScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist),
      const SettingsScreen(),
    ];
  }

  // Función Maestra para iniciar reproducción de listas
  void _playPlaylist(List<SongModel> queue, int index) {
    setState(() {
      _currentQueue = queue;
      _currentSongIndex = index;
    });
    
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(
        initialQueue: queue, 
        initialIndex: index, 
        audioPlayer: _audioPlayer
      ),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 1 
          ? HomeScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist) 
          : _pages[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xFF161622).withOpacity(0.95),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))]
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
    );
  }

  Widget _navBtn(IconData icon, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          if (_audioPlayer.audioSource != null) {
            // Abrir player con el estado actual
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(
              initialQueue: _currentQueue, 
              initialIndex: _audioPlayer.currentIndex ?? 0, 
              audioPlayer: _audioPlayer,
              isContinuing: true // Bandera para no reiniciar audio
            )));
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF0F0F1E)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          )
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("CUICATL", style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const Icon(Icons.search, size: 28),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildPill("Música", 0),
                    _buildPill("Artistas", 1),
                    _buildPill("Álbumes", 2),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildBodyContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white10,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(text, style: GoogleFonts.outfit(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
        )),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedTab == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("For you ($_userName)", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: _playRandomMix,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]),
              ),
              child: Stack(
                children: [
                  Positioned(right: -20, bottom: -30, child: Icon(Icons.shuffle, size: 180, color: Colors.black.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Mix Aleatorio", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 5),
                        const Text("Música sorpresa para tu estado\nde ánimo.", style: TextStyle(fontSize: 13, color: Colors.white)),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("Reproducir", style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.play_arrow, size: 16)]),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("Todas las canciones", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<SongModel>>(
              future: _audioQuery.querySongs(sortType: SongSortType.DATE_ADDED, orderType: OrderType.DESC_OR_GREATER, uriType: UriType.EXTERNAL, ignoreCase: true),
              builder: (context, item) {
                if (item.data == null) return const Center(child: CircularProgressIndicator());
                if (item.data!.isEmpty) return const Center(child: Text("Sin canciones."));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: item.data!.length,
                  itemBuilder: (context, index) => _songTile(item.data![index], item.data!, index),
                );
              },
            ),
          ),
        ],
      );
    }
    // Tabs de Artistas y Álbumes simplificados para ahorrar espacio
    if (_selectedTab == 1) {
      return FutureBuilder<List<ArtistModel>>(
        future: _audioQuery.queryArtists(),
        builder: (context, item) {
          if (item.data == null) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: item.data!.length,
            itemBuilder: (context, index) => ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person)),
                title: Text(item.data![index].artist),
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
    return Container();
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

// --- FAVORITOS ---
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
  void initState() {
    super.initState();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _favIds = prefs.getStringList('favorites') ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Favoritos ❤️"), backgroundColor: Colors.transparent, elevation: 0),
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.querySongs(),
        builder: (context, item) {
          if (item.data == null) return const Center(child: CircularProgressIndicator());
          List<SongModel> favSongs = item.data!.where((element) => _favIds.contains(element.id.toString())).toList();
          if (favSongs.isEmpty) return const Center(child: Text("Aún no tienes favoritos."));
          return ListView.builder(
            itemCount: favSongs.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: QueryArtworkWidget(id: favSongs[index].id, type: ArtworkType.AUDIO, nullArtworkWidget: const Icon(Icons.music_note)),
                title: Text(favSongs[index].title),
                subtitle: Text(favSongs[index].artist ?? ""),
                onTap: () => widget.onPlayRequest(favSongs, index),
              );
            },
          );
        },
      ),
    );
  }
}

// --- AJUSTES ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración ⚙️"), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             ListTile(leading: const Icon(Icons.graphic_eq), title: const Text("Ecualizador"), onTap: (){}),
             const Divider(color: Colors.white24),
             ListTile(
              leading: const Icon(Icons.person_remove), 
              title: const Text("Cerrar Sesión"), 
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.remove('userName');
                if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
              }),
          ],
        ),
      ),
    );
  }
}

// --- REPRODUCTOR (PLAYER) OPTIMIZADO ---
class PlayerScreen extends StatefulWidget {
  final List<SongModel> initialQueue;
  final int initialIndex;
  final AudioPlayer audioPlayer;
  final bool isContinuing;

  const PlayerScreen({
    super.key, 
    required this.initialQueue, 
    required this.initialIndex, 
    required this.audioPlayer,
    this.isContinuing = false
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isFav = false;
  
  // Usamos Streams para evitar reconstruir todo el Widget
  Stream<Duration>? _positionStream;
  Stream<Duration?>? _durationStream;
  Stream<int?>? _currentIndexStream;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Iniciar Streams
    _positionStream = widget.audioPlayer.positionStream;
    _durationStream = widget.audioPlayer.durationStream;
    _currentIndexStream = widget.audioPlayer.currentIndexStream;

    if (!widget.isContinuing) {
      _initPlaylist();
    } else {
      _isPlaying = widget.audioPlayer.playing;
      _checkFav(widget.initialQueue[widget.initialIndex]);
    }

    // Escuchar cambios de canción para el carrusel y favoritos
    widget.audioPlayer.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        setState(() => _currentIndex = index);
        if (_pageController.hasClients && _pageController.page?.round() != index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
        _checkFav(widget.initialQueue[index]);
      }
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  Future<void> _initPlaylist() async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: widget.initialQueue.map((song) => AudioSource.uri(Uri.parse(song.uri!))).toList(),
      );
      await widget.audioPlayer.setAudioSource(playlist, initialIndex: widget.initialIndex);
      widget.audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading playlist: $e");
    }
  }

  Future<void> _checkFav(SongModel song) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];
    setState(() => _isFav = favs.contains(song.id.toString()));
  }

  Future<void> _toggleFav() async {
    final song = widget.initialQueue[_currentIndex];
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];
    String id = song.id.toString();
    
    if (favs.contains(id)) {
      favs.remove(id);
      setState(() => _isFav = false);
    } else {
      favs.add(id);
      setState(() => _isFav = true);
    }
    await prefs.setStringList('favorites', favs);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialQueue.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentSong = widget.initialQueue.isNotEmpty ? widget.initialQueue[_currentIndex] : null;

    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO ESTÁTICO (Optimizado para evitar Flickering)
          // Usamos un RepaintBoundary para aislar el pintado del fondo
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(
                  child: QueryArtworkWidget(
                    id: currentSong?.id ?? 0, 
                    type: ArtworkType.AUDIO,
                    artworkHeight: MediaQuery.of(context).size.height,
                    artworkWidth: MediaQuery.of(context).size.height,
                    artworkQuality: FilterQuality.high, // Máxima calidad
                    size: 1000,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(color: const Color(0xFF2E1065)),
                  ),
                ),
                Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.black.withOpacity(0.6)))),
              ],
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          SafeArea(
            child: Column(
              children: [
                // Header Glass
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassBtn(Icons.keyboard_arrow_down, () => Navigator.pop(context)),
                      Text(currentSong?.artist ?? "Artista", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                      _glassBtn(Icons.ios_share, () {}),
                    ],
                  ),
                ),
                
                const Spacer(),

                // 3. CARRUSEL DE CARÁTULAS (PageView)
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.initialQueue.length,
                    onPageChanged: (index) {
                      widget.audioPlayer.seek(Duration.zero, index: index);
                    },
                    itemBuilder: (context, index) {
                      final song = widget.initialQueue[index];
                      return Center(
                        child: Container(
                          height: 300, width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: QueryArtworkWidget(
                              id: song.id, type: ArtworkType.AUDIO, 
                              artworkHeight: 300, artworkWidth: 300,
                              artworkQuality: FilterQuality.high,
                              size: 1000, // Fuerza alta resolución
                              nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 100, color: Colors.white24)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // 4. INFO TEXTO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentSong?.artist ?? "Unknown", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white60)),
                            const SizedBox(height: 4),
                            Text(
                              currentSong?.title ?? "Canción", 
                              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: _isFav ? const Color(0xFF8B5CF6) : Colors.white54, size: 28),
                        onPressed: _toggleFav,
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 5. BARRA DE ESPECTRO INTERACTIVA (Waveform SeekBar)
                StreamBuilder<Duration>(
                  stream: _positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: _durationStream,
                      builder: (context, snapshotDur) {
                        final duration = snapshotDur.data ?? Duration.zero;
                        return Column(
                          children: [
                            // La Barra de Onda
                            WaveformSlider(
                              position: position,
                              duration: duration,
                              onSeek: (seekPos) => widget.audioPlayer.seek(seekPos),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                                  Text(_formatDuration(duration), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                                ],
                              ),
                            )
                          ],
                        );
                      }
                    );
                  }
                ),

                const SizedBox(height: 10),

                // 6. CONTROLES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.shuffle, color: Colors.white54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white), 
                      onPressed: () => widget.audioPlayer.seekToPrevious()),
                    
                    GestureDetector(
                      onTap: () => _isPlaying ? widget.audioPlayer.pause() : widget.audioPlayer.play(),
                      child: Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), 
                      onPressed: () => widget.audioPlayer.seekToNext()),
                    IconButton(icon: const Icon(Icons.repeat, color: Colors.white54), onPressed: () {}),
                  ],
                ),
                
                const Spacer(),
                
                // 7. SWIPE HANDLE (Extendido al fondo)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(0, 15, 0, MediaQuery.of(context).padding.bottom + 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 20),
                      Text("Swipe for lyrics", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                )
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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}

// --- WIDGET PERSONALIZADO: WAVEFORM SLIDER ---
class WaveformSlider extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const WaveformSlider({
    super.key, 
    required this.position, 
    required this.duration, 
    required this.onSeek
  });

  @override
  Widget build(BuildContext context) {
    // Número de barras a dibujar
    const int barCount = 35; 
    final double percentage = duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds;
    
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);
        final p = (localPos.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(Duration(milliseconds: (duration.inMilliseconds * p).round()));
      },
      onTapUp: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);
        final p = (localPos.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(Duration(milliseconds: (duration.inMilliseconds * p).round()));
      },
      child: Container(
        height: 50,
        width: double.infinity,
        color: Colors.transparent, // Necesario para detectar taps
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            // Generamos una "onda" visual simétrica falsa pero bonita
            final double waveHeight = 10 + (15 * sin(index * 0.5).abs()) + (Random(index).nextInt(15).toDouble());
            final bool isActive = index / barCount <= percentage;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: isActive ? waveHeight + 5 : waveHeight, // Efecto "pop" al activarse
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white24,
                borderRadius: BorderRadius.circular(5),
                boxShadow: isActive ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.5), blurRadius: 5)] : null
              ),
            );
          }),
        ),
      ),
    );
  }
}
