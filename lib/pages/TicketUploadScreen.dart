import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

// Define custom colors based on the logo
const Color romanOrange = Color(0xFFF26522);
const Color romanLightGray = Color(0xFFB0B7C0);
const Color romanDarkGray = Color(0xFF4A4E54);
const Color romanWhite = Color(0xFFFFFFFF);

class TicketUploadScreen extends StatefulWidget {
  const TicketUploadScreen({super.key});

  @override
  _TicketUploadScreenState createState() => _TicketUploadScreenState();
}

class _TicketUploadScreenState extends State<TicketUploadScreen> {
  File? _ticketImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  bool _isUploaded = false;
  String _extractedText = '';
  Map<String, String> _parsedData = {};

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _ticketImage = File(pickedFile.path);
        _isUploaded = false;
        _extractedText = '';
        _parsedData = {};
      });
    }
  }

  Future<void> _processTicket() async {
    if (_ticketImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final textDetector = GoogleMlKit.vision.textRecognizer();
      final inputImage = InputImage.fromFilePath(_ticketImage!.path);
      final RecognizedText recognizedText =
          await textDetector.processImage(inputImage);

      String fullText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          fullText += '${line.text}\n';
        }
      }

      final parsedData = _parseTicketData(fullText);

      setState(() {
        _extractedText = fullText;
        _parsedData = parsedData;
        _isUploaded = true;
      });

      _showResultsDialog(context, parsedData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar ticket: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Map<String, String> _parseTicketData(String fullText) {
    final Map<String, String> result = {};
    final lines = fullText.split('\n');

    final dateRegex = RegExp(r'(\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4})');
    final totalRegex =
        RegExp(r'(TOTAL|TOTAL USD|TOTAL MXN)\s*[\$]?\s*(\d+\.\d{2})');
    final storeRegex =
        RegExp(r'([A-Z][A-Z\s]+[A-Z])\s*(TIENDA|SUC\.|Sucursal)');

    for (String line in lines) {
      if (result['date'] == null) {
        final dateMatch = dateRegex.firstMatch(line);
        if (dateMatch != null) {
          result['date'] = dateMatch.group(1)!;
        }
      }

      if (result['total'] == null) {
        final totalMatch = totalRegex.firstMatch(line);
        if (totalMatch != null) {
          result['total'] = totalMatch.group(2)!;
        }
      }

      if (result['store'] == null) {
        final storeMatch = storeRegex.firstMatch(line);
        if (storeMatch != null) {
          result['store'] = storeMatch.group(1)!;
        }
      }
    }

    return result;
  }

  void _showResultsDialog(BuildContext context, Map<String, String> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Datos del Ticket', style: TextStyle(color: romanDarkGray)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['store'] != null)
                _buildDataRow('Tienda:', data['store']!),
              if (data['date'] != null) _buildDataRow('Fecha:', data['date']!),
              if (data['total'] != null)
                _buildDataRow('Total:', '\$${data['total']}'),
              const SizedBox(height: 16),
              Text(
                'Texto completo reconocido:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: romanDarkGray),
              ),
              SizedBox(height: 8),
              Text(
                _extractedText,
                style: TextStyle(fontSize: 12, color: romanDarkGray),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: romanOrange)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Puntos añadidos correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: romanOrange,
              foregroundColor: romanWhite,
            ),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: romanDarkGray),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: romanDarkGray)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitCircle(
                    color: romanOrange, // Updated to logo orange
                    size: 50.0,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Procesando tu ticket...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: romanOrange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analizando texto y extrayendo datos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: romanLightGray,
                        ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sube tu ticket',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: romanDarkGray,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escanea o carga tu ticket para acumular puntos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: romanLightGray,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: romanWhite, // Changed to logo white
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _ticketImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 60,
                                  color: romanLightGray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay ticket seleccionado',
                                  style: TextStyle(
                                    color: romanLightGray,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Image.file(
                                    _ticketImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  if (_isUploaded)
                                    Container(
                                      color: Colors.green.withOpacity(0.7),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: romanWhite,
                                              size: 50,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Ticket procesado',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: romanWhite,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_ticketImage == null || !_isUploaded) ...[
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: Icon(Icons.camera_alt, color: romanWhite),
                      label: Text('Tomar foto del ticket',
                          style: TextStyle(color: romanWhite)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: romanOrange,
                        foregroundColor: romanWhite,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: Icon(Icons.photo_library, color: romanOrange),
                      label: Text('Seleccionar de galería',
                          style: TextStyle(color: romanOrange)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: romanOrange,
                        side: BorderSide(color: romanOrange),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  if (_ticketImage != null && !_isUploaded) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _processTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: romanOrange,
                        foregroundColor: romanWhite,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, color: romanWhite),
                          SizedBox(width: 8),
                          Text(
                            'Enviar ticket',
                            style: TextStyle(fontSize: 16, color: romanWhite),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Divider(color: romanLightGray),
                  const SizedBox(height: 16),
                  Text(
                    '¿Cómo subir tu ticket?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: romanDarkGray,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    icon: Icons.camera_alt,
                    title: 'Toma una foto clara',
                    description: 'Asegúrate que el ticket esté bien iluminado',
                  ),
                  _buildInstructionStep(
                    icon: Icons.receipt,
                    title: 'Incluye toda la información',
                    description: 'Fecha, monto y código deben ser visibles',
                  ),
                  _buildInstructionStep(
                    icon: Icons.verified,
                    title: 'Espera la confirmación',
                    description: 'Tus puntos se añadirán automáticamente',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: romanOrange, // Updated to logo orange
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: romanDarkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: romanLightGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
