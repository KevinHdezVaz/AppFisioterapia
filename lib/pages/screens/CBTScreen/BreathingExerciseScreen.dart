import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class BreathingExerciseScreen extends StatefulWidget {
  @override
  _BreathingExerciseScreenState createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _scaleAnimation;
  String _instruction = "Preparado para comenzar";
  int _completedCycles = 0;
  bool _isPlaying = false;

  // Duraciones específicas para cada fase (en segundos)
  double _inhaleDuration = 4.0; // Inhalar: 4 segundos
  double _holdDuration = 7.0; // Mantener: 7 segundos
  double _exhaleDuration = 8.0; // Exhalar: 8 segundos
  late double _totalDuration; // Duración total del ciclo

  @override
  void initState() {
    super.initState();
    // Calcular la duración total del ciclo
    _totalDuration = _inhaleDuration + _holdDuration + _exhaleDuration;
    _setupAnimations();
  }

  void _setupAnimations() {
    _breathController = AnimationController(
      duration: Duration(seconds: _totalDuration.toInt()),
      vsync: this,
    );

    // Calcular los pesos (weight) para cada fase basados en las duraciones
    final inhaleWeight = (_inhaleDuration / _totalDuration) * 100;
    final holdWeight = (_holdDuration / _totalDuration) * 100;
    final exhaleWeight = (_exhaleDuration / _totalDuration) * 100;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 4.5),
        weight: inhaleWeight, // Inhala: crece de 0.8 a 4.5 en 4 segundos
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(4.5),
        weight: holdWeight, // Mantén: permanece en 4.5 durante 7 segundos
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 4.5, end: 0.8),
        weight: exhaleWeight, // Exhala: reduce de 4.5 a 0.8 en 8 segundos
      ),
    ]).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.linear, // Usar curva lineal para sincronización exacta
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleCycleCompletion();
        }
      });
  }

  void _startBreathing() {
    setState(() {
      _isPlaying = true;
      _completedCycles = 0;
      _instruction = "Inhala...";
    });
    _breathController.forward();
    _updateBreathingPhases();
  }

  void _updateBreathingPhases() {
    // Calcular los puntos de corte para cada fase basados en las duraciones
    final inhaleEnd = _inhaleDuration / _totalDuration;
    final holdEnd = (_inhaleDuration + _holdDuration) / _totalDuration;

    _breathController.addListener(() {
      final value = _breathController.value;
      final elapsedTime = value * _totalDuration;

      if (value < inhaleEnd) {
        // Inhala
        final remainingTime = _inhaleDuration - elapsedTime;
        setState(() =>
            _instruction = "Inhala... (${remainingTime.toStringAsFixed(1)}s)");
      } else if (value < holdEnd) {
        // Mantén
        final phaseElapsedTime = elapsedTime - _inhaleDuration;
        final remainingTime = _holdDuration - phaseElapsedTime;
        setState(() =>
            _instruction = "Mantén... (${remainingTime.toStringAsFixed(1)}s)");
      } else {
        // Exhala
        final phaseElapsedTime =
            elapsedTime - (_inhaleDuration + _holdDuration);
        final remainingTime = _exhaleDuration - phaseElapsedTime;
        setState(() =>
            _instruction = "Exhala... (${remainingTime.toStringAsFixed(1)}s)");
      }
    });
  }

  void _handleCycleCompletion() {
    setState(() => _completedCycles++);

    if (_completedCycles < 5) {
      Future.delayed(Duration(seconds: 1), () {
        _breathController.reset();
        _breathController.forward();
      });
    } else {
      setState(() {
        _isPlaying = false;
        _instruction = "¡Sesión completada!";
      });
    }
  }

  void _pauseResume() {
    if (_breathController.isAnimating) {
      _breathController.stop();
      setState(() => _isPlaying = false);
    } else {
      _breathController.forward();
      setState(() => _isPlaying = true);
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Respiración Guiada"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity, // Asegura que ocupe todo el ancho
          height: double.infinity, // Asegura que ocupe toda la altura
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [LumorahColors.primary.withOpacity(0.1), Colors.white],
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Distribución uniforme
            children: [
              // Espacio adicional en la parte superior
              SizedBox(height: 20),
              // Círculo de respiración animado
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LumorahColors.primary.withOpacity(0.2),
                      border: Border.all(
                        color: LumorahColors.primary.withOpacity(
                          0.8 - (_breathController.value * 0.5).clamp(0.3, 0.8),
                        ),
                        width: 8,
                      ),
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LumorahColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Espacio flexible para empujar el texto hacia el centro
              Spacer(),
              // Instrucción actual
              Text(
                _instruction,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: LumorahColors.primary,
                ),
              ),
              SizedBox(height: 20),
              // Contador de ciclos
              Text(
                "Ciclo: ${_completedCycles.clamp(0, 5)}/5",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              // Espacio flexible para empujar el botón hacia abajo
              Spacer(),
              // Botón de control
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: _isPlaying ? _pauseResume : _startBreathing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isPlaying ? Colors.red[400] : LumorahColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isPlaying ? "Pausar" : "Comenzar",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
