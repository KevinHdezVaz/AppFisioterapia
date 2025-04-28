import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/auth/login_page.dart';
import 'package:user_auth_crudd10/model/Premio.dart';
import 'package:user_auth_crudd10/model/Promocion.dart';
import 'package:user_auth_crudd10/pages/PromotionsScreen.dart';
import 'package:user_auth_crudd10/pages/RewardsScreen.dart';
import 'package:user_auth_crudd10/services/PremioService.dart';
import 'package:user_auth_crudd10/services/PromocionesService.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Promocion>> _promocionesFuture;
  late Future<List<Premio>> _premiosFuture;
  final PromocionService _promocionService = PromocionService();
  final PremioService _premioService = PremioService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _promocionesFuture = _promocionService.fetchPromociones();
    _premiosFuture = _premioService.fetchPremios();
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        backgroundColor: LumorahColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Points Card

            const SizedBox(height: 16),

            // Promotions Card
            FutureBuilder<List<Promocion>>(
              future: _promocionesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: LumorahColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                final promociones = snapshot.data ?? [];
                if (promociones.isEmpty) {
                  return Card(
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay promociones disponibles'),
                    ),
                  );
                }

                final promocion = promociones.firstWhere(
                  (p) => p.estado.toLowerCase() == 'activa',
                  orElse: () => promociones.first,
                );

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promociones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: LumorahColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          promocion.titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: LumorahColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promocion.descripcion ?? 'Oferta especial',
                          style: TextStyle(
                            fontSize: 16,
                            color: LumorahColors.textLight,
                          ),
                        ),
                        if (promocion.puntosPorTicket > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Gana ${promocion.puntosPorTicket} puntos por ticket',
                            style: TextStyle(
                              fontSize: 14,
                              color: LumorahColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LumorahColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PromotionsScreen(),
                                ),
                              );
                            },
                            child: const Text('Ver promociones'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Awards Card
            FutureBuilder<List<Premio>>(
              future: _premiosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: LumorahColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }

                final premios = snapshot.data ?? [];
                if (premios.isEmpty) {
                  return Card(
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay premios disponibles'),
                    ),
                  );
                }

                final premiosActivos = premios
                    .where((p) => p.estado.toLowerCase() == 'activo')
                    .toList();
                final premiosMostrar = premiosActivos.length >= 2
                    ? premiosActivos.sublist(0, 2)
                    : premiosActivos;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premios disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: LumorahColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...premiosMostrar.map((premio) => Column(
                              children: [
                                _buildAwardItem(
                                  premio.titulo,
                                  '${premio.puntosRequeridos} puntos',
                                  Icons.card_giftcard,
                                  _getColorForPremio(premio),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RewardsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                if (premio != premiosMostrar.last)
                                  const Divider(height: 16),
                              ],
                            )),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LumorahColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RewardsScreen(),
                                ),
                              );
                            },
                            child: const Text('Ver todos los premios'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPremio(Premio premio) {
    switch (premio.estado.toLowerCase()) {
      case 'activo':
        return LumorahColors.primary;
      case 'inactivo':
        return LumorahColors.primaryLighter;
      case 'sin_stock':
        return LumorahColors.error;
      default:
        return LumorahColors.primaryDark;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildAwardItem(
    String title,
    String points,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: LumorahColors.textLight,
                ),
              ),
              Text(
                points,
                style: TextStyle(
                  fontSize: 14,
                  color: LumorahColors.primary.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: LumorahColors.primary,
          ),
        ],
      ),
    );
  }
}
