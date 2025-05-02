import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/CBTExercise.dart';
import 'package:user_auth_crudd10/pages/screens/CBTScreen/BreathingExerciseScreen.dart';
import 'package:user_auth_crudd10/pages/screens/CBTScreen/ThoughtRecordScreen.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class CBTScreen extends StatelessWidget {
  final List<CBTExercise> exercises = [
    CBTExercise(
      title: "Registro de Pensamientos",
      description: "Identifica y replantea pensamientos negativos",
      icon: Icons.edit,
      screen: ThoughtRecordScreen(),
    ),
    CBTExercise(
      title: "Respiración Guiada",
      description: "Técnica para reducir ansiedad",
      icon: Icons.self_improvement,
      screen: BreathingExerciseScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Ejercicios CBT",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _buildExerciseCard(context, exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, CBTExercise exercise) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => exercise.screen,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      LumorahColors.primaryLight,
                      LumorahColors.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  exercise.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
