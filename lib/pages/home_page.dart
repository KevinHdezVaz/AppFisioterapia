import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/pages/screens/CBTScreen/CBTScreen.dart';
import 'package:user_auth_crudd10/pages/screens/chats/ChatScreen.dart';
import 'package:user_auth_crudd10/services/ChatServiceApi.dart';
import 'package:user_auth_crudd10/utils/colors.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../utils/DailyTipsManager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DailyTipsManager _tipsManager = DailyTipsManager();
  final ChatServiceApi _chatService = ChatServiceApi();
  final AuthService _authService = AuthService(); // Instancia de AuthService
  bool _isScreenVisible = true;
  List<dynamic> _recentChats = [];
  bool _isLoadingChats = true;
  String? _chatErrorMessage;
  String _userName = 'Usuario'; // Nombre del usuario por defecto

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tipsManager.addListener(_updateState);
    _fetchRecentChats();
    _fetchUserProfile(); // Obtener el nombre del usuario
  }

  Future<void> _fetchRecentChats() async {
    setState(() {
      _isLoadingChats = true;
      _chatErrorMessage = null;
    });

    try {
      final chats = await _chatService.getSessions();
      setState(() {
        _recentChats = chats;
        _isLoadingChats = false;
      });
    } catch (e) {
      setState(() {
        _chatErrorMessage = 'Error al cargar los chats: $e';
        _isLoadingChats = false;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profileData = await _authService.getProfile();
      setState(() {
        _userName =
            profileData['name'] ?? 'Usuario'; // Obtener el nombre del perfil
      });
    } catch (e) {
      setState(() {
        _userName = 'Usuario'; // Usar valor por defecto en caso de error
      });
    }
  }

  void _updateState() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tipsManager.startAutoAdvance();
    } else {
      _tipsManager.stopAutoAdvance();
    }
  }

  @override
  void dispose() {
    _tipsManager.removeListener(_updateState);
    _tipsManager.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Función para formatear la fecha
  String formatDate(String date) {
    try {
      // Corregir el formato de la fecha eliminando el guion extra y ajustando el formato
      final correctedDate = date.replaceAll('T', ' ').replaceAll('- ', 'T');
      final parsedDate = DateTime.parse(correctedDate);
      return DateFormat('dd MMM, HH:mm')
          .format(parsedDate); // Ejemplo: "12 Feb, 16:00"
    } catch (e) {
      return 'Sin fecha';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumorahColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: LumorahColors.primary,
            elevation: 4,
            title: Text(
              'Lumorah Terapia',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: Badge(
                  smallSize: 8,
                  child:
                      const Icon(Icons.notifications_none, color: Colors.white),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      LumorahColors.primaryDark,
                      LumorahColors.primary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeCard(),
                const SizedBox(height: 30),
                _buildSectionTitle('Chats recientes', Icons.chat),
                const SizedBox(height: 16),
                _buildRecentChats(),
                const SizedBox(height: 30),
                _buildSectionTitle(
                    'Herramientas terapéuticas', Icons.medical_services),
                const SizedBox(height: 16),
                _buildToolsGrid(),
                const SizedBox(height: 30),
                _buildSectionTitle('Tu estado emocional', Icons.mood),
                const SizedBox(height: 16),
                _buildMoodTracker(),
                const SizedBox(height: 30),
                _buildDailyTip(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LumorahColors.primary.withOpacity(0.9),
            LumorahColors.primaryDark.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: LumorahColors.primaryDark.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Hola, $_userName', // Usar el nombre dinámico
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¿Cómo te sientes hoy?',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: LumorahColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Iniciar sesión de terapia',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: LumorahColors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChats() {
    if (_isLoadingChats) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_chatErrorMessage != null) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            _chatErrorMessage!,
            style: GoogleFonts.inter(color: LumorahColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_recentChats.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No hay chats recientes',
            style: GoogleFonts.inter(
              color: LumorahColors.textLight,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentChats.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final chat = _recentChats[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(sessionId: chat['id']),
                ),
              );
            },
            child: _buildChatCard(
              sessionId: chat['id'].toString(),
              date: chat['created_at'] ?? 'Sin fecha',
              topic: chat['topic'] ?? 'Chat #${chat['id']}',
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatCard({
    required String sessionId,
    required String date,
    required String topic,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LumorahColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble,
                    size: 18, color: LumorahColors.primary),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  sessionId,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: LumorahColors.primaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatDate(date), // Usar la función formatDate
            style: GoogleFonts.lato(
              color: LumorahColors.textLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: LumorahColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: LumorahColors.accent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              topic,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: LumorahColors.primaryDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildToolCard(
            Icons.music_note, 'Sonidos relajantes', LumorahColors.secondary),
        _buildToolCard(
            Icons.article_outlined, 'Diario emocional', LumorahColors.accent),
        _buildToolCard(
          Icons.psychology_outlined,
          'Ejercicios CBT',
          LumorahColors.info,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CBTScreen(), // Pantalla de ejercicios CBT
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolCard(IconData icon, String title, Color color,
      {VoidCallback? onTap}) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap, // Usamos la función proporcionada
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ver más',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTracker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: LumorahColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mood,
                      size: 20,
                      color: LumorahColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tu estado esta semana',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: LumorahColors.primary,
                ),
                child: Text(
                  'Registrar',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMoodDay('Lunes', '😊', true),
                _buildMoodDay('Martes', '😔', false),
                _buildMoodDay('Miércoles', '😊', true),
                _buildMoodDay('Jueves', '😐', false),
                _buildMoodDay('Viernes', '😊', true),
                _buildMoodDay('Sábado', '😃', true),
                _buildMoodDay('Domingo', '😢', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: LumorahColors.error.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(LumorahColors.success),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso semanal',
                style: GoogleFonts.lato(
                  color: LumorahColors.textLight,
                ),
              ),
              Text(
                '70% positivo',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: LumorahColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDay(String day, String emoji, bool positive) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: LumorahColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: positive
                  ? LumorahColors.success.withOpacity(0.1)
                  : LumorahColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: positive
                    ? LumorahColors.success.withOpacity(0.3)
                    : LumorahColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: LumorahColors.accent),
              const SizedBox(width: 8),
              Text(
                'Consejo del día',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: LumorahColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_tipsManager.currentIndex}/${_tipsManager.totalTips}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: LumorahColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _tipsManager.pageController,
            itemCount: _tipsManager.totalTips,
            onPageChanged: _tipsManager.onPageChanged,
            itemBuilder: (context, index) {
              final tipIndex = index % _tipsManager.totalTips;
              return _buildTipCard(_tipsManager.displayedTips[tipIndex]);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: LumorahColors.accent),
              onPressed: () {
                if (_tipsManager.pageController.hasClients) {
                  _tipsManager.previousTip();
                }
              },
            ),
            for (int i = 0; i < min(5, _tipsManager.totalTips); i++)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _tipsManager.currentIndex - 1 == i
                      ? LumorahColors.accent
                      : LumorahColors.accent.withOpacity(0.3),
                ),
              ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: LumorahColors.accent),
              onPressed: () {
                if (_tipsManager.pageController.hasClients) {
                  _tipsManager.nextTip();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LumorahColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LumorahColors.accent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: LumorahColors.accent,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            tip,
            style: GoogleFonts.lato(
              color: Colors.black,
              height: 1.5,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
