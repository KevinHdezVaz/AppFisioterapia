class User {
  final int id;
  final String nombre;
  final String email;
  final int saldoPuntos;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.saldoPuntos,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      saldoPuntos: json['saldo_puntos'],
    );
  }
}
