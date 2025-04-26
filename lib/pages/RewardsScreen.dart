import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/Premio.dart';
import 'package:user_auth_crudd10/services/PremioService.dart';

// Define custom colors based on the logo
const Color romanOrange = Color(0xFFF26522);
const Color romanLightGray = Color(0xFFB0B7C0);
const Color romanDarkGray = Color(0xFF4A4E54);
const Color romanWhite = Color(0xFFFFFFFF);

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final premioService = PremioService();

    return Scaffold(
      body: FutureBuilder<List<Premio>>(
        future: premioService.fetchPremios(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: romanOrange));
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: TextStyle(color: romanDarkGray)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No hay premios disponibles',
                    style: TextStyle(color: romanDarkGray)));
          }

          final premios = snapshot.data!;
          return Column(
            children: [
              // Header con puntos (simulado, ajusta según tu lógica)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: romanOrange, // Changed to solid orange
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.star,
                        color: Colors.amber, size: 36), // Kept amber for star
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TUS PUNTOS',
                          style: TextStyle(
                            color: romanWhite.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1250', // Simulado, ajusta con tu lógica
                          style: TextStyle(
                            color: romanWhite,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de premios
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: premios.length,
                  itemBuilder: (context, index) {
                    final premio = premios[index];
                    final requiredPoints = premio.puntosRequeridos;
                    final userPoints = 1250; // Simulado, ajusta con tu lógica
                    final canRedeem = userPoints >= requiredPoints;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: premio.imagen != null
                                ? Image.network(
                                    premio.imagen!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.broken_image,
                                            color: romanLightGray),
                                  )
                                : Container(
                                    height: 150,
                                    width: double.infinity,
                                    color: romanLightGray,
                                    child: Icon(Icons.image_not_supported,
                                        color: romanDarkGray),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getColorForEstado(premio.estado)
                                            .withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.card_giftcard,
                                        color:
                                            _getColorForEstado(premio.estado),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      premio.titulo,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: romanDarkGray,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  premio.descripcion ?? 'Sin descripción',
                                  style: TextStyle(
                                    color: romanLightGray,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      '$requiredPoints puntos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: romanOrange,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!canRedeem)
                                      Text(
                                        'Te faltan ${requiredPoints - userPoints} pts',
                                        style: TextStyle(
                                          color: Colors.red[400],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: canRedeem
                                        ? () =>
                                            _showRedeemDialog(context, premio)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canRedeem
                                          ? romanOrange
                                          : romanLightGray,
                                      foregroundColor: romanWhite,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      canRedeem
                                          ? 'CANJEAR AHORA'
                                          : 'PUNTOS INSUFICIENTES',
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, Premio premio) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_giftcard,
                color: romanOrange,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                '¿Confirmar canje?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: romanDarkGray,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Estás por canjear ${premio.puntosRequeridos} puntos por:',
                style: TextStyle(fontSize: 16, color: romanDarkGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                premio.titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: romanOrange,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: romanOrange,
                        side: BorderSide(color: romanOrange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Cancelar',
                          style: TextStyle(color: romanOrange)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡Canje exitoso! ${premio.titulo}'),
                            backgroundColor: Colors.green[800],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: romanOrange,
                        foregroundColor: romanWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Confirmar',
                          style: TextStyle(color: romanWhite)),
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

  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return romanOrange; // Updated to logo orange
      case 'inactivo':
        return romanLightGray; // Updated to logo light gray
      case 'sin_stock':
        return Colors.red; // Kept red for out-of-stock
      default:
        return romanDarkGray; // Updated to logo dark gray
    }
  }
}
