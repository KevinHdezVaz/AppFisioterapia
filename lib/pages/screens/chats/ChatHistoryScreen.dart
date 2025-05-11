import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LumorahAI/model/ChatMessage.dart';
import 'package:LumorahAI/model/ChatSession.dart';
import 'package:LumorahAI/pages/screens/chats/ChatScreen.dart';
import 'package:LumorahAI/services/ChatServiceApi.dart';
import 'package:LumorahAI/utils/colors.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ChatServiceApi _chatService = ChatServiceApi();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final Color tiffanyColor = Color(0xFF88D5C2);
  final Color ivoryColor = Color(0xFFFDF8F2);
  final Color darkTextColor = Colors.black87;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    try {
      setState(() => _isLoading = true);
      final sessions = await _chatService.getSessions(saved: true);
      setState(() {
        _sessions = sessions
            .where((session) => session.deletedAt == null && session.isSaved)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('errorLoadingConversations'.tr(args: [e.toString()]));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lora(color: Colors.white)),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  List<ChatSession> get _filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;

    return _sessions
        .where((session) =>
            session.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            _formatDate(session.createdAt)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _deleteSession(int id) async {
    try {
      await _chatService.deleteSession(id);
      setState(() {
        _sessions.removeWhere((session) => session.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('conversationDeleted'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('errorDeletingConversation'.tr(args: [e.toString()]));
    }
  }

  void _startNewConversation() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatScreen(
          initialMessages: [],
          inputMode: 'keyboard',
          sessionId: null,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tiffanyColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tiffanyColor, tiffanyColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'yourConversations'.tr(),
          style: GoogleFonts.lora(
            color: darkTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: darkTextColor, size: 28),
            onPressed: _fetchSessions,
          ),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        ),
        child: FloatingActionButton(
          onPressed: _startNewConversation,
          backgroundColor: ivoryColor,
          child: Icon(Icons.add, color: darkTextColor),
          tooltip: 'newConversation'.tr(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      color: ivoryColor.withOpacity(0.9),
                      elevation: 3,
                      shadowColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'searchConversations'.tr(),
                          hintStyle: GoogleFonts.lora(
                              color: darkTextColor.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.search, color: tiffanyColor),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        style: GoogleFonts.lora(
                            color: darkTextColor, fontSize: 16),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: ivoryColor,
                          strokeWidth: 3,
                        ),
                      )
                    : _filteredSessions.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: ivoryColor,
                            onRefresh: _fetchSessions,
                            child: ListView.builder(
                              padding: EdgeInsets.only(
                                  bottom: 24, left: 16, right: 16),
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
        ],
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    return Card(
      color: ivoryColor.withOpacity(0.9),
      elevation: 3,
      shadowColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ivoryColor.withOpacity(0.8), ivoryColor.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: tiffanyColor.withOpacity(0.2),
            child: Icon(
              Icons.bookmark,
              color: tiffanyColor,
              size: 24,
            ),
          ),
          title: Text(
            session.title,
            style: GoogleFonts.lora(
              color: darkTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(session.createdAt),
            style: GoogleFonts.lora(
              color: darkTextColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: tiffanyColor, size: 24),
            onPressed: () => _showDeleteDialog(session.id),
          ),
          onTap: () => _openChat(session),
        ),
      ),
    );
  }

  void _showDeleteDialog(int sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: ivoryColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: tiffanyColor, size: 48),
              SizedBox(height: 16),
              Text(
                'deleteConversation'.tr(),
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'deleteConversationPrompt'.tr(),
                style: GoogleFonts.lora(
                  fontSize: 16,
                  color: darkTextColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ivoryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'cancel'.tr(),
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.w600,
                        color: darkTextColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteSession(sessionId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tiffanyColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'delete'.tr(),
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: ivoryColor,
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
      final messages = await _chatService.getSessionMessages(session.id);
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ChatScreen(
            initialMessages: messages,
            inputMode: 'keyboard',
            sessionId: session.id,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 700),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('errorOpeningConversation'.tr(args: [e.toString()]));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 80,
              color: ivoryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'noConversations'.tr(),
              style: GoogleFonts.lora(
                color: darkTextColor,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'startNewConversationPrompt'.tr(),
              style: GoogleFonts.lora(
                color: darkTextColor.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startNewConversation,
              style: ElevatedButton.styleFrom(
                backgroundColor: ivoryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'newConversation'.tr(),
                style: GoogleFonts.lora(
                  color: darkTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

    final formattedTime = _formatTime(date);

    if (dateOnly == today) {
      return '${'todayAt'.tr()} $formattedTime';
    } else if (dateOnly == yesterday) {
      return '${'yesterdayAt'.tr()} $formattedTime';
    } else {
      return '${date.day}/${date.month}/${date.year} $formattedTime';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
