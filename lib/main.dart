import 'dart:ui';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';

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

// --- CONTROLADOR DE NAVEGACIÓN ---
class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});
  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _currentQueue = [];
  int _currentSongIndex = -1;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist),
      Container(), 
      FavoritesScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist),
      const SettingsScreen(),
    ];
  }

  void _playPlaylist(List<SongModel> queue, int index) {
    setState(() {
      _currentQueue = queue;
      _currentSongIndex = index;
    });
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(initialQueue: queue, initialIndex: index, audioPlayer: _audioPlayer),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 1 ? HomeScreen(audioPlayer: _audioPlayer, onPlayRequest: _playPlaylist) : _pages[_currentIndex],
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF2E1065), Color(0xFF0F0F1E)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
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
                child: Row(children: [_buildPill("Música", 0), _buildPill("Artistas", 1), _buildPill("Álbumes", 2)]),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBodyContent()),
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
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF8B5CF6) : Colors.white10, borderRadius: BorderRadius.circular(30)),
        child: Text(text, style: GoogleFonts.outfit(color: isSelected ? Colors.white : Colors.white60, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
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
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)])),
              child: Stack(
                children: [
                  Positioned(right: -20, bottom: -30, child: Icon(Icons.shuffle, size: 180, color: Colors.black.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
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
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Todas las canciones", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(
            child: FutureBuilder<List<SongModel>>(
              future: _audioQuery.querySongs(sortType: SongSortType.DATE_ADDED, orderType: OrderType.DESC_OR_GREATER, uriType: UriType.EXTERNAL, ignoreCase: true),
              builder: (context, item) {
                if (item.data == null) return const Center(child: CircularProgressIndicator());
                if (item.data!.isEmpty) return const Center(child: Text("Sin canciones."));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100), itemCount: item.data!.length,
                  itemBuilder: (context, index) => _songTile(item.data![index], item.data!, index),
                );
              },
            ),
          ),
        ],
      );
    }
    // Simplificado para Artistas y Albums
    if (_selectedTab == 1 || _selectedTab == 2) {
      return Center(child: Text("Sección en construcción", style: GoogleFonts.outfit(color: Colors.white54)));
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
  // Lógica de favoritos simplificada (similar a HomeScreen pero filtrado)
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Mis Favoritos"))); // Simplificado para ahorrar líneas
  }
}

// --- AJUSTES ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración"), backgroundColor: Colors.transparent),
      body: Center(child: Text("Ajustes", style: GoogleFonts.outfit())),
    );
  }
}

// --- REPRODUCTOR PREMIUM (ADAPTATIVE COLORS + LYRICS + MENU) ---
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
  
  // COLORES ADAPTATIVOS
  Color _adaptiveColor = const Color(0xFF8B5CF6); // Color por defecto (Violeta)
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
      _updatePalette(); // Generar color al abrir si ya suena
    }

    widget.audioPlayer.currentIndexStream.listen((index) {
      if (index != null && mounted) {
        setState(() => _currentIndex = index);
        if (_pageController.hasClients && _pageController.page?.round() != index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
        _updatePalette(); // CAMBIAR COLOR AL CAMBIAR CANCIÓN
      }
    });

    widget.audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
      if(state.playing) _waveController.repeat(); else _waveController.stop();
    });
  }

  Future<void> _initPlaylist() async {
    try {
      final playlist = ConcatenatingAudioSource(children: widget.initialQueue.map((song) => AudioSource.uri(Uri.parse(song.uri!))).toList());
      await widget.audioPlayer.setAudioSource(playlist, initialIndex: widget.initialIndex);
      widget.audioPlayer.play();
    } catch (e) { debugPrint("Error: $e"); }
  }

  // --- MAGIA: GENERADOR DE PALETA DE COLORES ---
  Future<void> _updatePalette() async {
    try {
      SongModel song = widget.initialQueue[_currentIndex];
      // Obtenemos los bytes de la imagen para analizarla
      Uint8List? artworkBytes = await OnAudioQuery().queryArtwork(song.id, ArtworkType.AUDIO, size: 500);
      
      if (artworkBytes != null) {
        final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(MemoryImage(artworkBytes));
        if (mounted) {
          setState(() {
            _adaptiveColor = palette.dominantColor?.color ?? const Color(0xFF8B5CF6);
            _adaptiveBackground = palette.darkMutedColor?.color ?? const Color(0xFF0F0F1E);
          });
        }
      } else {
        // Reset si no hay imagen
        setState(() { _adaptiveColor = const Color(0xFF8B5CF6); _adaptiveBackground = const Color(0xFF0F0F1E); });
      }
    } catch (e) { debugPrint("Error palette: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialQueue.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final currentSong = widget.initialQueue[_currentIndex];

    // Usamos DraggableScrollableSheet para el panel de letras
    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO QUE CAMBIA DE COLOR SUAVEMENTE
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [_adaptiveBackground.withOpacity(0.8), const Color(0xFF050505)], // Fondo dinámico oscuro
              )
            ),
          ),
          // Imagen de fondo extra desenfocada para textura
           Positioned.fill(
             child: RepaintBoundary(
               child: Opacity(
                 opacity: 0.4,
                 child: QueryArtworkWidget(
                  id: currentSong.id, type: ArtworkType.AUDIO, artworkHeight: MediaQuery.of(context).size.height, artworkWidth: MediaQuery.of(context).size.height,
                  size: 1000, artworkFit: BoxFit.cover, nullArtworkWidget: const SizedBox(),
                 ),
               ),
             ),
           ),
           BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),

          // 2. CONTENIDO PRINCIPAL
          SafeArea(
            child: Column(
              children: [
                // HEADER MENU
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassBtn(Icons.keyboard_arrow_down, () => Navigator.pop(context)),
                      Text("REPRODUCIENDO", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70, letterSpacing: 2)),
                      // BOTÓN DERECHO: MENÚ DE HERRAMIENTAS
                      PopupMenuButton<String>(
                        icon: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.more_vert, size: 20)),
                        color: const Color(0xFF1E1E2C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        onSelected: (value) {
                          if (value == 'timer') {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Temporizador: 30 min configurado 🌙")));
                            // Aquí iría la lógica real del timer
                          } else if (value == 'info') {
                             showDialog(context: context, builder: (_) => AlertDialog(
                               backgroundColor: const Color(0xFF1E1E2C),
                               title: const Text("Detalles del Archivo"),
                               content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                 Text("Formato: ${currentSong.fileExtension}"),
                                 Text("Duración: ${(currentSong.duration! / 1000 / 60).toStringAsFixed(2)} min"),
                                 const Text("Bitrate: Máximo disponible (Direct Source)"),
                               ]),
                             ));
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'timer', child: Row(children: [Icon(Icons.timer, color: Colors.white54), SizedBox(width: 10), Text("Sleep Timer")])),
                          const PopupMenuItem(value: 'info', child: Row(children: [Icon(Icons.info_outline, color: Colors.white54), SizedBox(width: 10), Text("Info de Calidad")])),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),

                // 3. CARRUSEL
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    controller: _pageController, itemCount: widget.initialQueue.length,
                    onPageChanged: (index) { widget.audioPlayer.seek(Duration.zero, index: index); },
                    itemBuilder: (context, index) {
                      return Center(
                        child: Container(
                          height: 300, width: 300,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15))]),
                          child: ClipRRect(borderRadius: BorderRadius.circular(30), child: QueryArtworkWidget(
                            id: widget.initialQueue[index].id, type: ArtworkType.AUDIO, artworkHeight: 300, artworkWidth: 300, size: 1000, quality: 100, // MAX CALIDAD
                            nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 100, color: Colors.white24)),
                          )),
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
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(currentSong.artist ?? "Desconocido", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white60)),
                          const SizedBox(height: 4),
                          Text(currentSong.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      IconButton(icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: _isFav ? _adaptiveColor : Colors.white54, size: 28), onPressed: () => setState(() => _isFav = !_isFav))
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 5. BARRA ONDA ADAPTATIVA
                StreamBuilder<Duration>(
                  stream: _positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: _durationStream,
                      builder: (context, snapshotDur) {
                        final duration = snapshotDur.data ?? Duration.zero;
                        return Column(children: [
                            WaveformSlider(position: position, duration: duration, color: _adaptiveColor, onSeek: (p) => widget.audioPlayer.seek(p)), // Color dinámico
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

                // 6. CONTROLES ADAPTATIVOS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.shuffle, color: Colors.white54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white), onPressed: () => widget.audioPlayer.seekToPrevious()),
                    GestureDetector(
                      onTap: () => _isPlaying ? widget.audioPlayer.pause() : widget.audioPlayer.play(),
                      child: Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(
                          color: _adaptiveColor.withOpacity(0.8), // COLOR DINÁMICO
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _adaptiveColor.withOpacity(0.4), blurRadius: 20)]
                        ),
                        child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white), onPressed: () => widget.audioPlayer.seekToNext()),
                    IconButton(icon: const Icon(Icons.repeat, color: Colors.white54), onPressed: () {}),
                  ],
                ),
                
                const SizedBox(height: 60), // Espacio para el BottomSheet
              ],
            ),
          ),

          // 7. LYRICS SHEET (PANEL DESLIZABLE)
          DraggableScrollableSheet(
            initialChildSize: 0.08,
            minChildSize: 0.08,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 15),
                    const Center(child: Text("LETRAS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2))),
                    const SizedBox(height: 20),
                    // AQUÍ IRÍAN LAS LETRAS REALES (Placeholder por ahora)
                    Text(
                      "No se encontraron letras incrustadas en el archivo.\n\nPara mostrar letras, el archivo de audio debe tener metadatos 'USLT' o 'SYLT' (ID3 tags).", 
                      textAlign: TextAlign.center, 
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16, height: 1.5)
                    ),
                    const SizedBox(height: 30),
                    OutlinedButton.icon(
                      onPressed: (){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buscando en web... (Próximamente)"))); }, 
                      icon: const Icon(Icons.search), 
                      label: const Text("Buscar letra en internet"),
                      style: OutlinedButton.styleFrom(foregroundColor: _adaptiveColor, side: BorderSide(color: _adaptiveColor))
                    )
                  ],
                ),
              );
            },
          )
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

// --- WAVEFORM SLIDER ADAPTATIVO ---
class WaveformSlider extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;
  final Color color; // Nuevo parámetro de color

  const WaveformSlider({super.key, required this.position, required this.duration, required this.onSeek, required this.color});

  @override
  Widget build(BuildContext context) {
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
        height: 50, width: double.infinity, color: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            final double waveHeight = 10 + (15 * sin(index * 0.5).abs()) + (Random(index).nextInt(15).toDouble());
            final bool isActive = index / barCount <= percentage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4, height: isActive ? waveHeight + 5 : waveHeight,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.white24, // USA EL COLOR ADAPTATIVO
                borderRadius: BorderRadius.circular(5),
                boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)] : null
              ),
            );
          }),
        ),
      ),
    );
  }
}
