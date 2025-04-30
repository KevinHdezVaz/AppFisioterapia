import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumorahColors.lightBackground,
      appBar: AppBar(
        backgroundColor: LumorahColors.primary,
        elevation: 0,
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
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Sesiones recientes'),
            const SizedBox(height: 16),
            _buildRecentSessions(),
            const SizedBox(height: 24),
            _buildSectionTitle('Herramientas'),
            const SizedBox(height: 16),
            _buildToolsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle('Estado emocional'),
            const SizedBox(height: 16),
            _buildMoodTracker(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LumorahColors.primary,
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LumorahColors.primary,
            LumorahColors.primaryDark,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, Alejandro',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¿Cómo te sientes hoy?',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navegar al chat
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: LumorahColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Iniciar sesión de terapia',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: LumorahColors.textDark,
      ),
    );
  }

  Widget _buildRecentSessions() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSessionCard('Hoy', '10:30 AM', 'Ansiedad'),
          const SizedBox(width: 12),
          _buildSessionCard('Ayer', '4:15 PM', 'Relaciones'),
          const SizedBox(width: 12),
          _buildSessionCard('Lunes', '9:00 AM', 'Autoestima'),
          const SizedBox(width: 12),
          _buildSessionCard('Viernes', '11:45 AM', 'Estrés'),
        ],
      ),
    );
  }

  Widget _buildSessionCard(String day, String time, String topic) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: LumorahColors.primaryDark,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.lato(
                  color: LumorahColors.textLight,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: LumorahColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              topic,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: LumorahColors.primaryDark,
              ),
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildToolCard(Icons.self_improvement, 'Meditación'),
        _buildToolCard(Icons.music_note, 'Sonidos relajantes'),
        _buildToolCard(Icons.article_outlined, 'Diario emocional'),
        _buildToolCard(Icons.psychology_outlined, 'Ejercicios'),
      ],
    );
  }

  Widget _buildToolCard(IconData icon, String title) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: LumorahColors.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: LumorahColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTracker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu estado esta semana',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: LumorahColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Registrar',
                  style: GoogleFonts.inter(
                    color: LumorahColors.primary,
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
                _buildMoodDay('L', '😊', true),
                _buildMoodDay('M', '😔', false),
                _buildMoodDay('M', '😊', true),
                _buildMoodDay('J', '😐', false),
                _buildMoodDay('V', '😊', true),
                _buildMoodDay('S', '😃', true),
                _buildMoodDay('D', '😢', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDay(String day, String emoji, bool positive) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Text(
            day,
            style: GoogleFonts.inter(
              color: LumorahColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: positive
                  ? LumorahColors.success.withOpacity(0.1)
                  : LumorahColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
