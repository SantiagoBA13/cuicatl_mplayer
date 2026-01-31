import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// PUNTO DE ENTRADA
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuración de pantalla completa (Inmersiva)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CuicatlApp());
}

// APP CONFIGURACIÓN
class CuicatlApp extends StatelessWidget {
  const CuicatlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuicatl Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
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

// GESTOR DE ESTADO (Login/Home)
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
    setState(() {
      _hasName = prefs.containsKey('userName');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasName == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // Si quieres saltar el registro la próxima vez, cambia esto. Por ahora pedimos nombre.
    if (_hasName == false) return const OnboardingScreen();
    return const MainHomeScreen();
  }
}

// PANTALLA DE BIENVENIDA
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
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainHomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF0F0F1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text("Bienvenido a Cuicatl", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "¿Cómo te llamas?",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Comenzar", style: TextStyle(color: Colors.white, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// PANTALLA PRINCIPAL (HOME - Diseño ECHOO)
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});
  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _userName = "Usuario";

  @override
  void initState() {
    super.initState();
    _loadName();
    _requestPermissions();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? "Usuario");
  }

  void _requestPermissions() async {
    await [Permission.storage, Permission.audio, Permission.mediaLibrary].request();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Importante para barra flotante
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF0F0F1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ECHOO", style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                      child: const Icon(Icons.search, size: 24),
                    ),
                  ],
                ),
              ),

              // TABS / PILLS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTab("All", true),
                    _buildTab("Music", false),
                    _buildTab("Podcasts", false),
                    _buildTab("Books", false),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // SECCIÓN: FOR YOU (Tarjeta Verde)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("For you", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              _buildForYouCard(),
              
              const SizedBox(height: 25),

              // SECCIÓN: POPULAR (Lista)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Popular", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text("Show all", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // LISTA DE CANCIONES
              Expanded(
                child: FutureBuilder<List<SongModel>>(
                  future: _audioQuery.querySongs(
                    sortType: SongSortType.DATE_ADDED,
                    orderType: OrderType.DESC_OR_GREATER,
                    uriType: UriType.EXTERNAL,
                    ignoreCase: true,
                  ),
                  builder: (context, item) {
                    if (item.data == null) return const Center(child: CircularProgressIndicator());
                    if (item.data!.isEmpty) return const Center(child: Text("Sin canciones encontradas."));
                    
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                      itemCount: item.data!.length,
                      itemBuilder: (context, index) {
                        return _buildSongTile(item.data![index], item.data!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8B5CF6) : Colors.white10, // Violeta activo
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: GoogleFonts.outfit(
        color: isSelected ? Colors.white : Colors.white60,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
      )),
    );
  }

  Widget _buildForYouCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF059669)], // Degradado Verde/Cyan
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Silueta decorativa (simulada)
          Positioned(
            right: -20, bottom: -30,
            child: Icon(Icons.person, size: 200, color: Colors.black.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Music for Your Mood", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text("Soundtracks that match your\nevery mood.", style: TextStyle(fontSize: 13, color: Colors.white)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text("Check out", style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.play_arrow, size: 16)],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFF161622).withOpacity(0.95), // Fondo casi negro
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.home_filled, true),
          _navIcon(Icons.explore_outlined, false),
          _navIcon(Icons.favorite_border, false),
          _navIcon(Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: isActive ? const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle) : null,
      child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 26),
    );
  }

  Widget _buildSongTile(SongModel song, List<SongModel> queue) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: QueryArtworkWidget(
          id: song.id, type: ArtworkType.AUDIO,
          nullArtworkWidget: Container(width: 55, height: 55, color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white30)),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(song.artist ?? "Desconocido", maxLines: 1, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      trailing: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(color: Colors.white24), shape: BoxShape.circle),
        child: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
      ),
      onTap: () {
        // NAVEGACIÓN AL REPRODUCTOR (Aquí estaba el fallo antes, ahora arreglado)
        Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => PlayerScreen(song: song, audioPlayer: _audioPlayer),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ));
      },
    );
  }
}

// PANTALLA REPRODUCTOR (PLAYER - Diseño Pantalla Izquierda)
class PlayerScreen extends StatefulWidget {
  final SongModel song;
  final AudioPlayer audioPlayer;
  const PlayerScreen({super.key, required this.song, required this.audioPlayer});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await widget.audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(widget.song.uri!)));
      widget.audioPlayer.play();
      widget.audioPlayer.playerStateStream.listen((state) { if(mounted) setState(() => _isPlaying = state.playing); });
      widget.audioPlayer.durationStream.listen((d) { if(mounted) setState(() => _duration = d ?? Duration.zero); });
      widget.audioPlayer.positionStream.listen((p) { if(mounted) setState(() => _position = p); });
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const ContainerIcon(icon: Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context)
        ),
        title: Text(widget.song.artist ?? "Artista", style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70)),
        centerTitle: true,
        actions: [
          IconButton(icon: const ContainerIcon(icon: Icons.ios_share), onPressed: () {})
        ],
      ),
      body: Stack(
        children: [
          // Fondo degradado
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF5B21B6), Color(0xFF0F0F1E)], // Morado oscuro a negro
            )
          )),
          // Desenfoque
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
          
          // Contenido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // CARÁTULA GRANDE
                Container(
                  height: 340, width: 340,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 20))]
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(35), child: QueryArtworkWidget(
                    id: widget.song.id, type: ArtworkType.AUDIO, artworkHeight: 340, artworkWidth: 340,
                    nullArtworkWidget: Container(color: Colors.white10, child: const Icon(Icons.music_note, size: 120, color: Colors.white24)),
                  )),
                ),
                const SizedBox(height: 40),
                
                // TÍTULO
                Align(alignment: Alignment.centerLeft, child: Text(widget.song.title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold))),
                const SizedBox(height: 30),

                // VISUALIZADOR DE ONDA (Simulado)
                SizedBox(height: 50, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(35, (i) => 
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3), 
                    width: 4, 
                    height: 15 + (i % 7) * 8.0 + (_isPlaying ? (i % 3) * 5 : 0),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(5)),
                  )
                ))),

                // BARRA PROGRESO
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Sin bolita, estilo minimalista
                    trackHeight: 4,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24
                  ),
                  child: Slider(
                    min: 0, max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                    onChanged: (v) => widget.audioPlayer.seek(Duration(seconds: v.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_formatDuration(_position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                ),

                const SizedBox(height: 20),

                // CONTROLES REPRODUCCIÓN
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  const Icon(Icons.shuffle, color: Colors.white54),
                  const Icon(Icons.skip_previous_rounded, size: 45, color: Colors.white),
                  GestureDetector(
                    onTap: () => _isPlaying ? widget.audioPlayer.pause() : widget.audioPlayer.play(),
                    child: Container(
                      padding: const EdgeInsets.all(22), 
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 35),
                    ),
                  ),
                  const Icon(Icons.skip_next_rounded, size: 45, color: Colors.white),
                  const Icon(Icons.repeat, color: Colors.white54),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}

// WIDGET AUXILIAR PARA BOTONES TRANSPARENTES
class ContainerIcon extends StatelessWidget {
  final IconData icon;
  const ContainerIcon({super.key, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }
}
