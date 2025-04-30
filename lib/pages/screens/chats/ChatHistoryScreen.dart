import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de Sesiones',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implementar búsqueda
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateSection('Esta semana'),
          _buildChatHistoryItem('Ansiedad matutina', 'Lunes, 10:30 AM', true),
          _buildChatHistoryItem('Problemas de sueño', 'Martes, 2:15 PM', false),
          _buildDateSection('Semana pasada'),
          _buildChatHistoryItem('Estrés laboral', 'Miércoles, 9:00 AM', true),
          _buildChatHistoryItem(
              'Relaciones personales', 'Viernes, 4:30 PM', true),
          _buildDateSection('Mayo 2023'),
          _buildChatHistoryItem('Primera sesión', '2 Mayo, 11:00 AM', false),
        ],
      ),
    );
  }

  Widget _buildDateSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: LumorahColors.primaryDark,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildChatHistoryItem(String title, String date, bool hasAttachment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: LumorahColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            color: LumorahColors.primary,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          date,
          style: GoogleFonts.lato(
            color: Colors.grey.shade600,
          ),
        ),
        trailing: hasAttachment
            ? const Icon(
                Icons.attachment,
                color: Colors.grey,
              )
            : null,
        onTap: () {
          // Navegar a los detalles del chat histórico
        },
      ),
    );
  }
}
