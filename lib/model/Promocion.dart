class Promocion {
  final int id;
  final String titulo;
  final String? descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int puntosPorTicket;
  final double? montoMinimo;
  final String estado;
  final String? imagen;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promocion({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.puntosPorTicket,
    this.montoMinimo,
    required this.estado,
    this.imagen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promocion.fromJson(Map<String, dynamic> json) {
    return Promocion(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      puntosPorTicket: json['puntos_por_ticket'],
      montoMinimo: json['monto_minimo'] != null
          ? double.parse(json['monto_minimo'].toString())
          : null,
      estado: json['estado'],
      imagen: json['imagen'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
