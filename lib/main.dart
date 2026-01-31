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

// --- CONTROLADOR DE NAVEGACIÓN INFERIOR ---
class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});
  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(audioPlayer: _audioPlayer),
      Container(), // Placeholder Player
      FavoritesScreen(audioPlayer: _audioPlayer),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 1 
          ? HomeScreen(audioPlayer: _audioPlayer) 
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(audioPlayer: _audioPlayer)));
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

// --- PANTALLA PRINCIPAL (HOME) ---
class HomeScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const HomeScreen({super.key, required this.audioPlayer});
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
      _openPlayer(songs.first, songs); 
    }
  }

  void _openPlayer(dynamic item, List<dynamic> queue) {
    SongModel song;
    if (item is SongModel) {
      song = item;
    } else {
      return; 
    }

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(song: song, audioPlayer: widget.audioPlayer),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
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
                  itemBuilder: (context, index) => _songTile(item.data![index]),
                );
              },
            ),
          ),
        ],
      );
    }
    
    if (_selectedTab == 1) {
      return FutureBuilder<List<ArtistModel>>(
        future: _audioQuery.queryArtists(sortType: ArtistSortType.ARTIST, orderType: OrderType.ASC_OR_SMALLER, uriType: UriType.EXTERNAL, ignoreCase: true),
        builder: (context, item) {
          if (item.data == null) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: item.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(height: 50, width: 50, decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white54)),
                title: Text(item.data![index].artist, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${item.data![index].numberOfTracks} canciones"),
                onTap: () async {
                  List<SongModel> artistSongs = await _audioQuery.queryAudiosFrom(AudiosFromType.ARTIST_ID, item.data![index].id);
                  if(artistSongs.isNotEmpty) _openPlayer(artistSongs.first, artistSongs);
                },
              );
            },
          );
        },
      );
    }

    if (_selectedTab == 2) {
      return FutureBuilder<List<AlbumModel>>(
        future: _audioQuery.queryAlbums(sortType: AlbumSortType.ALBUM, orderType: OrderType.ASC_OR_SMALLER, uriType: UriType.EXTERNAL, ignoreCase: true),
        builder: (context, item) {
          if (item.data == null) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: item.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: QueryArtworkWidget(id: item.data![index].id, type: ArtworkType.ALBUM, nullArtworkWidget: Container(width: 50, height: 50, color: Colors.white10, child: const Icon(Icons.album))),
                title: Text(item.data![index].album, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.data![index].artist ?? "Varios"),
                onTap: () async {
                  List<SongModel> albumSongs = await _audioQuery.queryAudiosFrom(AudiosFromType.ALBUM_ID, item.data![index].id);
                  if(albumSongs.isNotEmpty) _openPlayer(albumSongs.first, albumSongs);
                },
              );
            },
          );
        },
      );
    }
    return Container();
  }

  Widget _songTile(SongModel song) {
    return ListTile(
      leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO, nullArtworkWidget: Container(width: 50, height: 50, color: Colors.white10, child: const Icon(Icons.music_note)))),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(song.artist ?? "Desconocido", style: const TextStyle(fontSize: 12, color: Colors.white54)),
      trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF8B5CF6)),
      onTap: () => _openPlayer(song, []),
    );
  }
}

// --- PANTALLA FAVORITOS ---
class FavoritesScreen extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const FavoritesScreen({super.key, required this.audioPlayer});
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    _favIds.remove(favSongs[index].id.toString());
                    await prefs.setStringList('favorites', _favIds);
                    setState(() {});
                  },
                ),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(song: favSongs[index], audioPlayer: widget.audioPlayer)));
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- PANTALLA AJUSTES ---
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
            ListTile(
              leading: const Icon(Icons.graphic_eq, color: Color(0xFF8B5CF6), size: 30),
              title: const Text("Ecualizador"),
              subtitle: const Text("Abrir ecualizador del sistema"),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Abriendo EQ del sistema..."))),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.color_lens, color: Color(0xFF34D399), size: 30),
              title: const Text("Personalización"),
              subtitle: const Text("Cambiar nombre de usuario"),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.remove('userName');
                if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
              },
            ),
             const Divider(color: Colors.white24),
             const SizedBox(height: 20),
             const Text("Versión Cuicatl 2.5 - Build Github", style: TextStyle(color: Colors.white30)),
          ],
        ),
      ),
    );
  }
}

// --- REPRODUCTOR (PLAYER) ESTILO ECHOO (ACTUALIZADO) ---
class PlayerScreen extends StatefulWidget {
  final SongModel? song;
  final AudioPlayer audioPlayer;
  const PlayerScreen({super.key, this.song, required this.audioPlayer});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isFav = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  SongModel? _currentSong;
  
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    if (_currentSong != null) _initPlayer();
    else _syncPlayer(); 
    _checkFav();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _checkFav() async {
    if (_currentSong == null) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];
    setState(() => _isFav = favs.contains(_currentSong!.id.toString()));
  }

  Future<void> _toggleFav() async {
    if (_currentSong == null) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList('favorites') ?? [];
    String id = _currentSong!.id.toString();
    
    if (favs.contains(id)) {
      favs.remove(id);
      setState(() => _isFav = false);
    } else {
      favs.add(id);
      setState(() => _isFav = true);
    }
    await prefs.setStringList('favorites', favs);
  }

  Future<void> _initPlayer() async {
    try {
      await widget.audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(_currentSong!.uri!)));
      widget.audioPlayer.play();
      _syncPlayer();
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _syncPlayer() {
    widget.audioPlayer.playerStateStream.listen((state) { 
      if(mounted) {
        setState(() => _isPlaying = state.playing);
        if(!state.playing) _waveController.stop(); else _waveController.repeat();
      }
    });
    widget.audioPlayer.durationStream.listen((d) { if(mounted) setState(() => _duration = d ?? Duration.zero); });
    widget.audioPlayer.positionStream.listen((p) { if(mounted) setState(() => _position = p); });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSong == null && widget.audioPlayer.audioSource == null) return const Scaffold(body: Center(child: Text("...")));

    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO ATMOSFÉRICO
          Positioned.fill(
            child: QueryArtworkWidget(
              id: _currentSong?.id ?? 0, 
              type: ArtworkType.AUDIO,
              artworkHeight: MediaQuery.of(context).size.height,
              artworkWidth: MediaQuery.of(context).size.height,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(color: const Color(0xFF2E1065)),
            ),
          ),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.black.withOpacity(0.5)))),

          // CONTENIDO
          SafeArea(
            child: Column(
              children: [
                // 2. HEADER GLASS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassBtn(Icons.keyboard_arrow_down, () => Navigator.pop(context)),
                      Text(_currentSong?.artist ?? "Artista", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                      _glassBtn(Icons.ios_share, () {}),
                    ],
                  ),
                ),
                
                const Spacer(),

                // 3. CARÁTULA FLOTANTE 3D
                Container(
                  height: 300, width: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, offset: const Offset(0, 20))]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: QueryArtworkWidget(
                      id: _currentSong?.id ?? 0, type: ArtworkType.AUDIO, artworkHeight: 300, artworkWidth: 300,
                      nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 100, color: Colors.white24)),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // 4. INFO ALINEADA IZQUIERDA
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
                            Text("Año 202X", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60)),
                            const SizedBox(height: 4),
                            Text(
                              _currentSong?.title ?? "Canción", 
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

                // 5. VISUALIZADOR ONDA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(20, (index) {
                                  double height = 10 + Random().nextInt(40).toDouble() * (_isPlaying ? 1.0 : 0.1); 
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 4,
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                      Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
                // Slider invisible
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                    trackHeight: 0,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    min: 0, max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                    onChanged: (v) => widget.audioPlayer.seek(Duration(seconds: v.toInt())),
                  ),
                ),

                const SizedBox(height: 10),

                // 6. CONTROLES GLASS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.shuffle, color: Colors.white54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 40, color: Colors.white), onPressed: () {}),
                    
                    GestureDetector(
                      onTap: () => _isPlaying ? widget.audioPlayer.pause() : widget.audioPlayer.play(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 35, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 40, color: Colors.white), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.repeat, color: Colors.white54), onPressed: () {}),
                  ],
                ),
                
                const Spacer(),
                
                // 7. SWIPE HANDLE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white.withOpacity(0.1),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
