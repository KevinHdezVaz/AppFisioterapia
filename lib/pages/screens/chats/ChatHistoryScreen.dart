import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/model/ChatMessage.dart';
import 'package:user_auth_crudd10/model/ChatSession.dart';
import 'package:user_auth_crudd10/pages/screens/chats/ChatScreen.dart';
import 'package:user_auth_crudd10/services/ChatServiceApi.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatServiceApi _chatService = ChatServiceApi();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      setState(() => _isLoading = true);
      final sessions = await _chatService.getSessions();
      setState(() {
        // Validar y asignar las sesiones
        if (sessions is List<ChatSession>) {
          _sessions =
              sessions.where((session) => session.deletedAt == null).toList();
        } else {
          throw FormatException(
              'Se esperaba List<ChatSession>, se obtuvo ${sessions.runtimeType}');
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar tus conversaciones: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lora(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<ChatSession> get _filteredSessions {
    var filtered = _sessions.toList(); // Mostrar todas las sesiones sin filtro

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((session) =>
              session.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              _formatDate(session.createdAt).contains(_searchQuery))
          .toList();
    }

    return filtered;
  }

  Future<void> _deleteSession(int id) async {
    try {
      await _chatService.deleteSession(id);
      setState(() {
        _sessions.removeWhere((session) => session.id == id);
      });
    } catch (e) {
      _showError('Error al eliminar la conversación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumorahColors.primary,
      appBar: AppBar(
        title: Text(
          'Tus Conversaciones',
          style: GoogleFonts.lora(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSessions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar conversaciones...',
                    hintStyle: GoogleFonts.lora(),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.lora(color: Colors.white),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(
                    height:
                        8), // Mantenemos el espacio para consistencia visual
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: LumorahColors.secondary,
                    ),
                  )
                : _filteredSessions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: LumorahColors.secondary,
                        onRefresh: _fetchSessions,
                        child: ListView.builder(
                          padding: EdgeInsets.only(bottom: 16),
                          itemCount: _filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return _buildSessionCard(session);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          session.isSaved ? Icons.bookmark : Icons.chat_bubble_outline,
          color: LumorahColors.secondary,
        ),
        title: Text(
          session.title,
          style: GoogleFonts.lora(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _formatDate(session.createdAt),
          style: GoogleFonts.lora(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[200]),
          onPressed: () => _showDeleteDialog(session.id),
        ),
        onTap: () => _openChat(session),
      ),
    );
  }

  void _showDeleteDialog(int sessionId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Color(0xFFFDF8F2), // marfil suave
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color.fromARGB(255, 214, 126, 18), size: 48),
              SizedBox(height: 16),
              Text(
                '¿Eliminar esta conversación?',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Este espacio ha sido parte de tu proceso.\n¿Deseas dejarlo ir?',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF88D5C2),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteSession(sessionId);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(
                      'Eliminar',
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(ChatSession session) async {
    try {
      // 1. Obtener mensajes guardados de la sesión
      final messagesJson = await _chatService.getSessionMessages(session.id);

      // 2. Convertir a objetos ChatMessage
      final messages = messagesJson
          .map<ChatMessage>(
              (json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      // 3. Navegar al ChatScreen con los mensajes recuperados
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            initialMessages: messages,
            inputMode: 'keyboard',
            sessionId: session.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Error al abrir la conversación: $e');
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined,
                size: 64, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No hay conversaciones',
              style: GoogleFonts.lora(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza una nueva conversación',
              style: GoogleFonts.lora(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hoy a las ${_formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'Ayer a las ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
