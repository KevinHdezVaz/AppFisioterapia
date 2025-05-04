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
  bool _showOnlySaved = true; // Variable para filtrar chats guardados

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      setState(() => _isLoading = true);
      final sessionsJson = await _chatService.getSessions();
      setState(() {
        _sessions = sessionsJson
            .map((json) => ChatSession.fromJson(json))
            .where((session) => session.deletedAt == null)
            .toList();
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
    var filtered = _sessions
        .where((session) => !_showOnlySaved || session.isSaved)
        .toList();

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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Mostrar solo guardados',
                        style: GoogleFonts.lora(color: Colors.white70)),
                    Switch(
                      value: _showOnlySaved,
                      activeColor: LumorahColors.secondary,
                      onChanged: (value) =>
                          setState(() => _showOnlySaved = value),
                    ),
                  ],
                ),
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
      builder: (context) => AlertDialog(
        title: Text('Eliminar conversación', style: GoogleFonts.lora()),
        content: Text('¿Estás seguro de eliminar esta conversación?',
            style: GoogleFonts.lora()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.lora()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(sessionId);
            },
            child: Text('Eliminar', style: GoogleFonts.lora(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(ChatSession session) async {
    try {
      final messagesJson = await _chatService.getSessionMessages(session.id);
      final messages = messagesJson
          .map<ChatMessage>(
              (json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatMessages: messages,
            inputMode: 'keyboard',
            sessionId: session.id,
          ),
        ),
      );
    } catch (e) {
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
              _showOnlySaved
                  ? 'No hay conversaciones guardadas'
                  : 'No hay conversaciones',
              style: GoogleFonts.lora(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlySaved
                  ? 'Intenta desactivar el filtro de guardados'
                  : 'Comienza una nueva conversación',
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
