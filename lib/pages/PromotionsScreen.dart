import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Promocion.dart';
import 'package:user_auth_crudd10/services/PromocionesService.dart';

// Define custom colors based on the logo
const Color romanOrange = Color(0xFFF26522);
const Color romanLightGray = Color(0xFFB0B7C0);
const Color romanDarkGray = Color(0xFF4A4E54);
const Color romanWhite = Color(0xFFFFFFFF);

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promocionService = PromocionService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Promociones', style: TextStyle(color: romanWhite)),
        backgroundColor: romanOrange,
        elevation: 0,

        automaticallyImplyLeading: false, // Disable back arrow
        leading: null, // Ensure no leading widget
      ),
      body: FutureBuilder<List<Promocion>>(
        future: promocionService.fetchPromociones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: romanOrange));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: romanDarkGray)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No hay promociones disponibles',
                    style: TextStyle(color: romanDarkGray)));
          }

          final promociones = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promociones.length,
            itemBuilder: (context, index) {
              final promocion = promociones[index];
              final color = _getColorForEstado(promocion.estado);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        children: [
                          promocion.imagen != null
                              ? Image.network(
                                  promocion.imagen!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.broken_image,
                                          color: romanLightGray),
                                )
                              : Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: romanLightGray,
                                  child: Icon(Icons.image_not_supported,
                                      color: romanDarkGray),
                                ),
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promocion.titulo,
                                  style: TextStyle(
                                    color: romanWhite,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Puntos por ticket: ${promocion.puntosPorTicket}',
                                  style: TextStyle(
                                    color: romanWhite,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_offer,
                                color: color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Estado: ${promocion.estado}',
                                style: TextStyle(
                                  color: romanDarkGray,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                // Acción para obtener promoción
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: romanOrange,
                                foregroundColor: romanWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'OBTENER PROMOCIÓN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: romanWhite,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activa':
        return romanOrange; // Updated to logo orange
      case 'inactiva':
        return romanLightGray; // Updated to logo light gray
      case 'expirada':
        return Colors.red; // Kept red for expired
      default:
        return romanDarkGray; // Updated to logo dark gray
    }
  }
}
