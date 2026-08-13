import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

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

  // أدخل مفتاح OpenAI الخاص بك هنا
  final String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';

  Future<void> _processText() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      _showSnackBar('يرجى إدخال نص أولاً');
      return;
    }

    setState(() {
      _isLoading = true;
      _translatedText = "";
      _extendedDescription = "";
    });

    String prompt = "";

    if (_currentMode == 'translate') {
      prompt = "You are an expert translator and editor. "
          "Task: If the following text is in English or any non-Arabic language, translate it directly into fluent, natural, and highly accurate Arabic. "
          "If the text is already in Arabic, enhance its style, grammar, and flow. "
          "Do NOT add any preamble, intro, or explanations. Respond ONLY with the finalized Arabic text:\n\n$input";
    } else {
      prompt = "You are an expert content expander and writer. "
          "Task: Explain the following text thoroughly in rich, structured, and beautiful Arabic. "
          "Provide detailed context, key takeaways, and clear paragraphs with headings. "
          "Start immediately with the extended Arabic content without meta commentary:\n\n$input";
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
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
        final resultText = data['choices'][0]['message']['content'].toString().trim();

        setState(() {
          if (_currentMode == 'translate') {
            _translatedText = resultText;
          } else {
            _extendedDescription = resultText;
          }
        });
      } else {
        setState(() {
          _translatedText = "خطأ في الاستجابة (${response.statusCode}):\nتأكد من صحة مفتاح الـ API والرصيد المتاح.";
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = "تعذر الاتصال بالشبكة.\nيرجى التأكد من اتصال الجهاز بالإنترنت والتحقق مجدداً.\nالتفاصيل: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareResult(String text) {
    if (text.trim().isEmpty) return;
    Share.share(text, subject: 'النتيجة من تطبيق المترجم والمحلل');
  }

  void _copyToClipboard(String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('تم نسخ النص إلى الحافظة بنجاح');
  }

  void _clearInput() {
    _controller.clear();
    setState(() {
      _translatedText = "";
      _extendedDescription = "";
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'sans-serif')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المترجم والمحلل الذكي'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // مربع إدخال النص
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'أدخل النص الإنجليزي أو العربي هنا...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(15.0),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: _clearInput,
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 16.0, color: Colors.black87),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'عدد الحروف: ${_controller.text.length}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            'عدد الكلمات: ${_controller.text.trim().isEmpty ? 0 : _controller.text.trim().split(RegExp(r'\s+')).length}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // خيارات الوضع (ترجمة أو شرح)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('ترجمة / تحسين')),
                      selected: _currentMode == 'translate',
                      selectedColor: Colors.indigo.shade900,
                      labelStyle: TextStyle(
                        color: _currentMode == 'translate' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentMode = 'translate');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('شرح / توسيع')),
                      selected: _currentMode == 'extend',
                      selectedColor: Colors.indigo.shade900,
                      labelStyle: TextStyle(
                        color: _currentMode == 'extend' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (selected) {
                        if (selected) setState(() => _currentMode = 'extend');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // زر البدء
              ElevatedButton(
                onPressed: _isLoading ? null : _processText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _currentMode == 'translate' ? 'ابدأ الترجمة' : 'ابدأ الشرح والتوسيع',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),

              // منطقة عرض النتائج والأزرار
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    String textToDisplay = _currentMode == 'translate' ? _translatedText : _extendedDescription;
    String titleText = _currentMode == 'translate' ? 'الترجمة الناتج:' : 'الشرح الموسع:';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
              if (textToDisplay.isNotEmpty)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'نسخ',
                      onPressed: () => _copyToClipboard(textToDisplay),
                      color: Colors.indigo.shade900,
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _shareResult(textToDisplay),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text("فتح باستخدام"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const Divider(height: 20),
          Text(
            textToDisplay.isEmpty ? "ستظهر نتيجة الترجمة أو الشرح هنا بعد الضغط على الزر..." : textToDisplay,
            style: TextStyle(
              fontSize: 15.0,
              color: textToDisplay.isEmpty ? Colors.grey.shade500 : Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
