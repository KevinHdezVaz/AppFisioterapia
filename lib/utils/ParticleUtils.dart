import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:particles_flutter/component/particle/particle.dart';
 
class ParticleUtils {
  static List<Particle> createParticles({
    int numberOfParticles = 50,
    Color color = Colors.white,
    double maxSize = 5.0,
    double maxVelocity = 100.0,
  }) {
    var rng = Random();
    List<Particle> particles = [];
    for (int i = 0; i < numberOfParticles; i++) {
      particles.add(Particle(
        color: color.withOpacity(0.6),
        size: rng.nextDouble() * maxSize,
        velocity: Offset(
          rng.nextDouble() * maxVelocity * (rng.nextBool() ? 1 : -1),
          rng.nextDouble() * maxVelocity * (rng.nextBool() ? 1 : -1),
        ),
      ));
    }
    return particles;
  }
}