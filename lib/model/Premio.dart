class Premio {
  final int id;
  final String titulo;
  final String? descripcion;
  final int puntosRequeridos;
  final int? stock;
  final String estado;
  final String? imagen;
  final DateTime createdAt;
  final DateTime updatedAt;

  Premio({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.puntosRequeridos,
    this.stock,
    required this.estado,
    this.imagen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Premio.fromJson(Map<String, dynamic> json) {
    return Premio(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      puntosRequeridos: json['puntos_requeridos'],
      stock: json['stock'],
      estado: json['estado'],
      imagen: json['imagen'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
