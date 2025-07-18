import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:open_file/open_file.dart';
import '../../services/text_to_pdf_service.dart';
import '../../providers/pdf_provider.dart';

class VoiceToPdfScreen extends ConsumerStatefulWidget {
  const VoiceToPdfScreen({super.key});

  @override
  ConsumerState<VoiceToPdfScreen> createState() => _VoiceToPdfScreenState();
}


class _VoiceToPdfScreenState extends ConsumerState<VoiceToPdfScreen> {
  final Map<String, String> _languages = {
    'English': 'en_US',
    'Kannada': 'kn_IN',
    'Hindi': 'hi_IN',
  };
  String _selectedLanguage = 'en_US';
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  final TextEditingController _titleController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (error) {
            setState(() {
              _isListening = false;
              _errorMsg = 'Speech recognition error: \\${error.errorMsg}';
            });
          },
        );
        if (available) {
          setState(() {
            _isListening = true;
            _errorMsg = null;
          });
          _speech.listen(
            onResult: (val) => setState(() {
              _text = val.recognizedWords;
            }),
            listenFor: const Duration(minutes: 2),
            pauseFor: const Duration(seconds: 3),
            cancelOnError: true,
            localeId: _selectedLanguage,
          );
        } else {
          setState(() {
            _errorMsg = 'Speech recognition unavailable.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMsg = 'Microphone permission denied or unavailable.';
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _clearText() {
    setState(() {
      _text = '';
      _errorMsg = null;
    });
  }

  Future<void> _savePdf() async {
    if (_text.trim().isEmpty) {
      setState(() => _errorMsg = 'Cannot save empty note.');
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });
    try {
      final pdfBytes = await TextToPdfService.createPdfFromText(
        _text,
        title: _titleController.text,
      );
      final pdfName = (_titleController.text.isNotEmpty ? _titleController.text : 'VoiceNote') + '.pdf';
      final pdfProvider = ref.read(pdfListProvider.notifier);
      final document = await pdfProvider.savePdfFromBytes(pdfBytes, pdfName);
      if (document != null) {
        // Open the PDF file after saving
        await OpenFile.open(document.path);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMsg = 'Failed to save PDF.';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice to PDF'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Language:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _languages.entries.firstWhere((e) => e.value == _selectedLanguage).key,
                    isExpanded: true,
                    items: _languages.keys.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (lang) {
                      if (lang != null) {
                        setState(() {
                          _selectedLanguage = _languages[lang]!;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'PDF Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMsg != null) ...[
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: TextEditingController(text: _text)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _text.length),
                          ),
                        onChanged: (val) => setState(() => _text = val),
                        minLines: 5,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Tap the mic and start speaking... or type here',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 18),
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 8),
                      if (_text.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            onPressed: _clearText,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    label: Text(_isListening ? 'Listening...' : 'Start Listening'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isProcessing ? null : _listen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(_isProcessing ? 'Saving...' : 'Save as PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isProcessing || _text.trim().isEmpty ? null : _savePdf,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
