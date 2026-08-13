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

  // خيارات التحكم بحجم الخط والألوان
  double _fontSize = 16.0;
  Color _textColor = Colors.black87;
  Color _resultCardColor = Colors.white;

  // ضع مفتاح OpenAI الخاص بك هنا
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
      prompt = "You are an advanced linguistic assistant and translator. "
          "Task 1: Pre-process the following text. Fix any typos, separated letters, or merged/run-on words. "
          "Task 2: Translate the cleaned text into high-quality Arabic. "
          "Task 3: Present the translation clearly, ideally mapping the Arabic translation alongside or above the original English terms so it does not overlap contextually. "
          "Do NOT add any intro, preamble, or meta explanations. Output ONLY the polished Arabic translation:\n\n$input";
    } else {
      prompt = "You are an expert content analyzer. "
          "Task 1: Correct any typos, broken character encoding, or merged words in the following text. "
          "Task 2: Provide a comprehensive, structured, and deep explanation of the text in clear Arabic. "
          "Start immediately with the extended explanation without intro comments:\n\n$input";
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
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.5,
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
          _translatedText = "خطأ في الاستجابة (${response.statusCode}): يرجى التأكد من مفتاح الـ API والاتصال.";
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = "حدث خطأ أثناء الاتصال بالشبكة: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareAppOrText(String text) {
    final textToShare = text.trim().isNotEmpty ? text : _controller.text.trim();
    if (textToShare.isEmpty) {
      _showSnackBar('لا يوجد نص لمشاركته أو تعريبه');
      return;
    }
    Share.share(textToShare, subject: 'تعريب وترجمة النص');
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
        content: Text(message),
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

              // اختيار الوضع (ترجمة / شرح)
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

              // زر بدء العملية
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
              const SizedBox(height: 15),

              // شريط أدوات التحكم (تكبير/تصغير الخط - تغيير الألوان - تعريب التطبيق)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // أزرار تكبير وتصغير النص
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                            tooltip: 'تكبير النص',
                            onPressed: () {
                              setState(() {
                                if (_fontSize < 30) _fontSize += 2;
                              });
                            },
                          ),
                          Text('${_fontSize.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.indigo),
                            tooltip: 'تصغير النص',
                            onPressed: () {
                              setState(() {
                                if (_fontSize > 12) _fontSize -= 2;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),

                      // زر تغيير لون النص والكرت
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.color_lens, color: Colors.indigo),
                        tooltip: 'تغيير الألوان',
                        onSelected: (value) {
                          setState(() {
                            if (value == 'blue') {
                              _textColor = Colors.blue.shade900;
                              _resultCardColor = Colors.blue.shade50;
                            } else if (value == 'green') {
                              _textColor = Colors.green.shade900;
                              _resultCardColor = Colors.green.shade50;
                            } else if (value == 'dark') {
                              _textColor = Colors.amber;
                              _resultCardColor = Colors.grey.shade900;
                            } else {
                              _textColor = Colors.black87;
                              _resultCardColor = Colors.white;
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'default', child: Text('الافتراضي')),
                          const PopupMenuItem(value: 'blue', child: Text('أزرق')),
                          const PopupMenuItem(value: 'green', child: Text('أخضر')),
                          const PopupMenuItem(value: 'dark', child: Text('داكن')),
                        ],
                      ),

                      // زر تعريب التطبيق / المشاركة
                      ElevatedButton.icon(
                        onPressed: () => _shareAppOrText(_currentMode == 'translate' ? _translatedText : _extendedDescription),
                        icon: const Icon(Icons.translate, size: 16),
                        label: const Text("تعريب التطبيق"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // منطقة إظهار النتائج
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    String textToDisplay = _currentMode == 'translate' ? _translatedText : _extendedDescription;
    String titleText = _currentMode == 'translate' ? 'الترجمة:' : 'الشرح الموسع:';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _resultCardColor,
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
              Row(
                children: [
                  if (textToDisplay.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'نسخ النص',
                      onPressed: () => _copyToClipboard(textToDisplay),
                      color: Colors.indigo.shade900,
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _shareAppOrText(textToDisplay),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("فتح باستخدام"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            textToDisplay.isEmpty ? "ستظهر نتيجة الترجمة أو الشرح هنا..." : textToDisplay,
            style: TextStyle(
              fontSize: _fontSize,
              color: textToDisplay.isEmpty ? Colors.grey.shade500 : _textColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
