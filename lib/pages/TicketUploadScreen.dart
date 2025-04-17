import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

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
      // 1. Extraer texto con OCR
      final textDetector = GoogleMlKit.vision.textRecognizer();
      final inputImage = InputImage.fromFilePath(_ticketImage!.path);
      final RecognizedText recognizedText =
          await textDetector.processImage(inputImage);

      // 2. Procesar texto del ticket
      String fullText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          fullText += '${line.text}\n';
        }
      }

      // 3. Parsear datos importantes
      final parsedData = _parseTicketData(fullText);

      setState(() {
        _extractedText = fullText;
        _parsedData = parsedData;
        _isUploaded = true;
      });

      // 4. Mostrar resultados
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

    // Expresiones regulares para datos comunes en tickets
    final dateRegex = RegExp(r'(\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4})');
    final totalRegex =
        RegExp(r'(TOTAL|TOTAL USD|TOTAL MXN)\s*[\$]?\s*(\d+\.\d{2})');
    final storeRegex =
        RegExp(r'([A-Z][A-Z\s]+[A-Z])\s*(TIENDA|SUC\.|Sucursal)');

    // Buscar datos en el texto
    for (String line in lines) {
      // Fecha
      if (result['date'] == null) {
        final dateMatch = dateRegex.firstMatch(line);
        if (dateMatch != null) {
          result['date'] = dateMatch.group(1)!;
        }
      }

      // Total
      if (result['total'] == null) {
        final totalMatch = totalRegex.firstMatch(line);
        if (totalMatch != null) {
          result['total'] = totalMatch.group(2)!;
        }
      }

      // Tienda
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
        title: const Text('Datos del Ticket'),
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
              const Text(
                'Texto completo reconocido:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _extractedText,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Puntos añadidos correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Ticket'),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitCircle(
                    color: Color(0xFF1E88E5),
                    size: 50.0,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Procesando tu ticket...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analizando texto y extrayendo datos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
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
                  // Header
                  Text(
                    'Sube tu ticket',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF212121),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escanea o carga tu ticket para acumular puntos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ), // This was the missing closing parenthesis
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _ticketImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay ticket seleccionado',
                                  style: TextStyle(
                                    color: Colors.grey[600],
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
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 50,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Ticket procesado',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
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

                  // Action Buttons
                  if (_ticketImage == null || !_isUploaded) ...[
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar foto del ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Seleccionar de galería'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        side: const BorderSide(color: Color(0xFF1E88E5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        backgroundColor: const Color(0xFFF57C00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload),
                          SizedBox(width: 8),
                          Text(
                            'Enviar ticket',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Help Section
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '¿Cómo subir tu ticket?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
            color: const Color(0xFF1E88E5),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
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
