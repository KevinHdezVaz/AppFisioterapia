import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/utils/colors.dart';

class ThoughtRecordScreen extends StatefulWidget {
  @override
  _ThoughtRecordScreenState createState() => _ThoughtRecordScreenState();
}

class _ThoughtRecordScreenState extends State<ThoughtRecordScreen> {
  final List<Map<String, String>> _records = [];
  final TextEditingController _situationController = TextEditingController();
  final TextEditingController _thoughtsController = TextEditingController();
  final TextEditingController _evidenceForController = TextEditingController();
  final TextEditingController _evidenceAgainstController =
      TextEditingController();
  final TextEditingController _alternativeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Registro de Pensamientos",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _continue,
                onStepCancel: _cancel,
                onStepTapped: (step) => setState(() => _currentStep = step),
                steps: [
                  _buildStep(
                    title: "Situación",
                    content: _buildTextField(
                      "Describe la situación que te afectó",
                      _situationController,
                      maxLines: 4,
                      icon: Icons.event_note,
                    ),
                  ),
                  _buildStep(
                    title: "Pensamientos",
                    content: _buildTextField(
                      "¿Qué pensamientos automáticos tuviste?",
                      _thoughtsController,
                      maxLines: 5,
                      icon: Icons.psychology,
                    ),
                  ),
                  _buildStep(
                    title: "Evidencia",
                    content: Column(
                      children: [
                        _buildTextField(
                          "Evidencia que apoya estos pensamientos",
                          _evidenceForController,
                          maxLines: 3,
                          icon: Icons.check_circle,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          "Evidencia que contradice estos pensamientos",
                          _evidenceAgainstController,
                          maxLines: 3,
                          icon: Icons.cancel,
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: "Alternativa",
                    content: _buildTextField(
                      "Pensamiento alternativo equilibrado",
                      _alternativeController,
                      maxLines: 5,
                      icon: Icons.autorenew,
                    ),
                  ),
                  _buildStep(
                    title: "Resumen",
                    content: _buildSummary(),
                    isComplete: true,
                  ),
                ],
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        if (_currentStep != 0)
                          OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              side: BorderSide(color: LumorahColors.primary),
                            ),
                            child: Text(
                              "Atrás",
                              style: TextStyle(color: LumorahColors.primary),
                            ),
                          ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LumorahColors.primary,
                            padding: EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: Text(
                            _currentStep == 3 ? "Finalizar" : "Siguiente",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: (_currentStep + 1) / 5,
      backgroundColor: Colors.grey[200],
      valueColor: AlwaysStoppedAnimation<Color>(LumorahColors.primary),
      minHeight: 4,
    );
  }

  Step _buildStep({
    required String title,
    required Widget content,
    bool isComplete = false,
  }) {
    return Step(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: content,
      state: _currentStep > 3 && isComplete
          ? StepState.complete
          : StepState.indexed,
      isActive: _currentStep >= 0,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 3, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Row(
            children: [
              Icon(icon, size: 20, color: LumorahColors.primary),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor completa este campo';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryItem("Situación", _situationController.text),
            Divider(),
            _buildSummaryItem("Pensamientos", _thoughtsController.text),
            Divider(),
            _buildSummaryItem("Evidencia a favor", _evidenceForController.text),
            Divider(),
            _buildSummaryItem(
                "Evidencia en contra", _evidenceAgainstController.text),
            Divider(),
            _buildSummaryItem(
                "Pensamiento alternativo", _alternativeController.text),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: LumorahColors.primary,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Guardar Registro", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String content) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: LumorahColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content.isNotEmpty ? content : "No completado",
            style: TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _continue() {
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    }
  }

  void _cancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _saveRecord() {
    final newRecord = {
      "date": DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      "situation": _situationController.text,
      "thoughts": _thoughtsController.text,
      "evidence_for": _evidenceForController.text,
      "evidence_against": _evidenceAgainstController.text,
      "alternative": _alternativeController.text,
    };

    setState(() => _records.add(newRecord));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Registro Guardado",
            style: TextStyle(color: LumorahColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("¡Bien hecho! Has completado el ejercicio."),
            SizedBox(height: 16),
            Text(
              "Fecha: ${newRecord["date"]}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
            },
            child: Text("Nuevo Registro",
                style: TextStyle(color: LumorahColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
              Navigator.pop(context); // Regresa a la pantalla anterior
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LumorahColors.primary,
            ),
            child: Text("Finalizar", style: TextStyle(color: Colors.white)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _resetForm() {
    _situationController.clear();
    _thoughtsController.clear();
    _evidenceForController.clear();
    _evidenceAgainstController.clear();
    _alternativeController.clear();
    setState(() => _currentStep = 0);
  }

  @override
  void dispose() {
    _situationController.dispose();
    _thoughtsController.dispose();
    _evidenceForController.dispose();
    _evidenceAgainstController.dispose();
    _alternativeController.dispose();
    super.dispose();
  }
}
