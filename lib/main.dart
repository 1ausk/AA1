import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MaterialApp(
    home: TranslatorApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class TranslatorApp extends StatefulWidget {
  const TranslatorApp({super.key});

  @override
  State<TranslatorApp> createState() => _TranslatorAppState();
}

class _TranslatorAppState extends State<TranslatorApp> {
  final TextEditingController _controller = TextEditingController();
  String _translatedText = "";
  String _extendedDescription = "";
  bool _isLoading = false;
  String _currentMode = 'translate'; // 'translate' or 'extend'

  Future<void> _processText() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _translatedText = "";
      _extendedDescription = "";
    });

    final sourceText = _controller.text;
    String prompt = "";

    if (_currentMode == 'translate') {
      prompt = "You are a professional translator. "
          "Translate the following English or foreign text into natural, accurate Arabic. "
          "If the input is already in Arabic, improve its style and grammar. "
          "Output ONLY the final Arabic translation without any explanations:\n\n$sourceText";
    } else {
      prompt = "You are an expert content expander. "
          "Explain the content of the following text thoroughly in rich Arabic. "
          "Start immediately with the detailed explanation:\n\n$sourceText";
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    const apiKey = 'YOUR_ACTUAL_API_KEY_HERE';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final resultText = data['choices'][0]['message']['content'];

        setState(() {
          if (_currentMode == 'translate') {
            _translatedText = resultText;
          } else {
            _extendedDescription = resultText;
          }
        });
      } else {
        setState(() {
          _translatedText = "خطأ في الاتصال [${response.statusCode}]: يرجى التأكد من مفتاح API.";
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = "حدث خطأ: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openWithExternalApp(String text) async {
    if (text.isEmpty) return;
    
    final Uri googleTranslateUri = Uri.parse(
      'https://translate.google.com/?sl=auto&tl=ar&text=${Uri.encodeComponent(_controller.text)}&op=translate'
    );

    if (await canLaunchUrl(googleTranslateUri)) {
      await launchUrl(googleTranslateUri, mode: LaunchMode.externalApplication);
    } else {
      Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ النص لعدم إمكانية فتح التطبيق الخارجي')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المترجم والمحلل'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'أدخل النص الإنجليزي أو العربي هنا...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(15.0),
                ),
                style: const TextStyle(fontSize: 16.0, color: Colors.black),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('ترجمة / تحسين', style: TextStyle(color: Colors.white)),
                    selected: _currentMode == 'translate',
                    selectedColor: Colors.indigo.shade900,
                    backgroundColor: Colors.grey.shade400,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentMode = 'translate';
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('شرح / توسيع', style: TextStyle(color: Colors.white)),
                    selected: _currentMode == 'extend',
                    selectedColor: Colors.indigo.shade900,
                    backgroundColor: Colors.grey.shade400,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentMode = 'extend';
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _isLoading ? null : _processText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_currentMode == 'translate' ? 'ابدأ الترجمة' : 'ابدأ الشرح'),
              ),
              const SizedBox(height: 25),
              _buildResultArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    String textToDisplay = _currentMode == 'translate' ? _translatedText : _extendedDescription;
    String titleText = _currentMode == 'translate' ? 'الترجمة:' : 'الشرح الموسع:';

    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openWithExternalApp(textToDisplay),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text("فتح باستخدام"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            textToDisplay.isEmpty ? "ستظهر النتيجة والترجمة هنا..." : textToDisplay,
            style: TextStyle(
              fontSize: 16.0,
              color: textToDisplay.isEmpty ? Colors.grey : Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
