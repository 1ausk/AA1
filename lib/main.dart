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
  bool _isOverlayActive = false;
  String _currentMode = 'translate';

  double _fontSize = 16.0;
  Color _textColor = Colors.black87;
  Color _resultCardColor = Colors.white;

  final String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';

  // قاموس عربي محلي سريع للتعريب الفوري للقوائم والنظام
  final Map<String, String> _builtInDictionary = {
    'save 1 item to...': 'حفظ عنصر واحد في...',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'untitled': 'بدون عنوان',
    'internal storage': 'وحدة التخزين الداخلية',
    'files saved on internal storage': 'الملفات المحفوظة على التخزين الداخلي',
    'mobidrive': 'موبي درايف',
    'your personal cloud storage by mobisystems...': 'مساحتك السحابية الشخصية',
    'add a cloud account': 'إضافة حساب سحابي',
    'ftp': 'بروتوكول نقل الملفات FTP',
    'local network': 'الشبكة المحلية',
    'downloads': 'التنزيلات',
    'pictures': 'الصور',
    'screenshots': 'لقطات الشاشة',
    'documents': 'المستندات',
    'settings': 'الإعدادات',
  };

  String _localDictionaryTranslate(String input) {
    String cleanInput = input.trim().toLowerCase();
    if (_builtInDictionary.containsKey(cleanInput)) {
      return _builtInDictionary[cleanInput]!;
    }
    
    // فحص وتحسين الكلمات المركبة والمفردات المتقاطعة
    _builtInDictionary.forEach((key, value) {
      if (cleanInput.contains(key)) {
        cleanInput = cleanInput.replaceAll(key, value);
      }
    });

    return cleanInput;
  }

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

    // تجربة الترجمة السريعة من القاموس المحلي أولاً
    final localResult = _localDictionaryTranslate(input);
    if (localResult != input.toLowerCase() && _currentMode == 'translate') {
      setState(() {
        _translatedText = localResult;
        _isLoading = false;
      });
      return;
    }

    String prompt = "";
    if (_currentMode == 'translate') {
      prompt = "You are an advanced linguistic assistant and overlay translator. "
          "Task 1: Correct typos, broken lines, or concatenated words. "
          "Task 2: Translate to clear, natural Arabic matching mobile UI context. "
          "Respond ONLY with the Arabic output:\n\n$input";
    } else {
      prompt = "You are a content analyzer. "
          "Explain the given text/UI terms thoroughly in Arabic. "
          "Output directly without intro comments:\n\n$input";
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
          'temperature': 0.3,
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
          _translatedText = "خطأ في الاتصال (${response.statusCode}): تحقق من المفتاح والإنترنت.";
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = "حدث خطأ أثناء الشبكة: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleTransparentOverlay() {
    setState(() {
      _isOverlayActive = !_isOverlayActive;
    });

    if (_isOverlayActive) {
      _showSnackBar('تم تفعيل الشاشة الشفافة! افتح التطبيق المراد تعريبه.');
    } else {
      _showSnackBar('تم إيقاف الشاشة الشفافة.');
    }
  }

  void _shareAppOrText(String text) {
    final textToShare = text.trim().isNotEmpty ? text : _controller.text.trim();
    if (textToShare.isEmpty) {
      _showSnackBar('لا يوجد نص لمشاركته');
      return;
    }
    Share.share(textToShare, subject: 'تعريب وترجمة النص');
  }

  void _copyToClipboard(String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('تم نسخ النص بنجاح');
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
        title: const Text('المترجم والمعرب الذكي'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // مربع الإدخال
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
                            hintText: 'أدخل النص أو القائمة المراد تعريبها...',
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

                  // أزرار الوضع
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('ترجمة / تعريب')),
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

                  // زر بدء التفسير/الترجمة
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
                            _currentMode == 'translate' ? 'ابدأ التعريب' : 'ابدأ الشرح',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 15),

                  // أجهزة التحكم والـ Overlay
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // حجم الخط
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.indigo),
                                    onPressed: () {
                                      setState(() {
                                        if (_fontSize < 30) _fontSize += 2;
                                      });
                                    },
                                  ),
                                  Text('${_fontSize.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.indigo),
                                    onPressed: () {
                                      setState(() {
                                        if (_fontSize > 12) _fontSize -= 2;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // قائمة الألوان
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.color_lens, color: Colors.indigo),
                                onSelected: (value) {
                                  setState(() {
                                    if (value == 'blue') {
                                      _textColor = Colors.blue.shade900;
                                      _resultCardColor = Colors.blue.shade50;
                                    } else if (value == 'green') {
                                      _textColor = Colors.green.shade900;
                                      _resultCardColor = Colors.green.shade50;
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
                                ],
                              ),

                              // زر تعريب التطبيق الشفاف
                              ElevatedButton.icon(
                                onPressed: _toggleTransparentOverlay,
                                icon: Icon(_isOverlayActive ? Icons.visibility_off : Icons.layers, size: 16),
                                label: Text(_isOverlayActive ? "إغلاق الشاشة الشفافة" : "تفعيل التعريب الشفاف"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isOverlayActive ? Colors.red.shade800 : Colors.indigo.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildResultCard(),
                ],
              ),
            ),

            // الطبقة الشفافة التفاعلية فوق القوائم والتطبيقات (Mock Overlay Engine)
            if (_isOverlayActive)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false, // يسمح باللمس والتفاعل
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 80,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade800, width: 1.5),
                            ),
                            child: const Text(
                              "وضع التعريب الشفاف نشط: سيتم ترجمة عناصر القوائم (مثل Internal Storage -> وحدة التخزين) فوق الأزرار مباشرة دون حجب التفاعل.",
                              style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // أمثلة لترجمات عائمة قابلة للتفاعل فوق عناصر الشاشة
                        Positioned(
                          top: 200,
                          right: 30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.85), borderRadius: BorderRadius.circular(5)),
                            child: const Text("وحدة التخزين الداخلية", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.85), borderRadius: BorderRadius.circular(5)),
                            child: const Text("إلغاء", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    String textToDisplay = _currentMode == 'translate' ? _translatedText : _extendedDescription;
    String titleText = _currentMode == 'translate' ? 'الترجمة / التعريب:' : 'الشرح الموسع:';

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
            textToDisplay.isEmpty ? "ستظهر نتيجة التعريب هنا..." : textToDisplay,
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
