import 'package:flutter/material.dart';

class ScreeningPage extends StatefulWidget {
  const ScreeningPage({super.key});

  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends State<ScreeningPage> {
  int _currentStep = 0;
  int? _selectedAgeGroup;
  Map<int, bool?> _answers = {};
  bool _isLoading = true;
  List<ScreeningQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _questions = [
        ScreeningQuestion(
          id: 1,
          text: "Berapa usia Anda?",
          isAgeQuestion: true,
          options: ["< 15 tahun", "≥ 15 tahun"],
        ),
        // Questions for age >= 15
        ScreeningQuestion(
          id: 12,
          text: "Apakah Anda mengalami batuk selama 2 minggu atau lebih?",
          forAgeGroup: 1, // >=15
          followUp: true,
          followUpQuestion: "Berapa lama batuk Anda (dalam hari)?",
        ),
        ScreeningQuestion(
          id: 13,
          text: "Apakah Anda mengalami batuk darah?",
          forAgeGroup: 1,
        ),
        // Questions for age < 15
        ScreeningQuestion(
          id: 12,
          text: "Apakah anak mengalami batuk selama 2 minggu atau lebih?",
          forAgeGroup: 0, // <15
          followUp: true,
          followUpQuestion: "Berapa lama batuk (dalam hari)?",
        ),
        ScreeningQuestion(
          id: 14,
          text:
              "Apakah berat badan anak turun/tidak naik dalam 2 bulan terakhir?",
          forAgeGroup: 0,
        ),
        ScreeningQuestion(
          id: 15,
          text: "Apakah anak mengalami demam ≥ 2 minggu?",
          forAgeGroup: 0,
        ),
        ScreeningQuestion(
          id: 16,
          text: "Apakah anak terlihat lesu atau kurang aktif bermain?",
          forAgeGroup: 0,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Skrining TB")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Skrining TB"),
        actions:
            _currentStep > 0
                ? [
                  TextButton(
                    onPressed: _showResult,
                    child: Text(
                      "Selesai",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ]
                : null,
      ),
      body: Stepper(
        key: ValueKey(_getFilteredQuestions().length),
        currentStep: _currentStep,
        onStepContinue: _continue,
        onStepCancel: _cancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep != 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    child: Text(
                      'Kembali',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _canContinue() ? details.onStepContinue : null,
                  child: Text(
                    _currentStep == _getFilteredQuestions().length - 1
                        ? 'Selesai'
                        : 'Lanjut',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          );
        },
        steps: _buildSteps(),
      ),
    );
  }

  List<Step> _buildSteps() {
    final filteredQuestions = _getFilteredQuestions();

    // Add intro step
    List<Step> steps = [
      Step(
        title: Text("Informasi Skrining"),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Skrining Evaluasi Mandiri TB",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "Skrining ini akan mengevaluasi gejala, usia, dan faktor risiko Anda terhadap Tuberkulosis (TB).",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Jawablah pertanyaan berikut dengan jujur untuk mendapatkan hasil yang akurat.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                "Waktu penyelesaian: 2-3 menit",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        isActive: _currentStep == 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
    ];

    // Add question steps
    steps.addAll(
      filteredQuestions.map((question) {
        final answer = _answers[question.id];
        final hasFollowUp = question.followUp && answer == true;

        return Step(
          title: Text("Pertanyaan ${filteredQuestions.indexOf(question) + 1}"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              if (question.isAgeQuestion)
                Column(
                  children:
                      question.options!.map((option) {
                        return RadioListTile<int>(
                          title: Text(option),
                          value: question.options!.indexOf(option),
                          groupValue: _selectedAgeGroup,
                          onChanged: (value) {
                            setState(() {
                              _selectedAgeGroup = value;
                              _answers[question.id] = value == 1;
                            });
                          },
                        );
                      }).toList(),
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setAnswer(question.id, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  answer == true ? Colors.green : null,
                            ),
                            child: Text(
                              "Ya",
                              style: TextStyle(
                                color:
                                    answer == true
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _setAnswer(question.id, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  answer == false ? Colors.red : null,
                            ),
                            child: Text(
                              "Tidak",
                              style: TextStyle(
                                color:
                                    answer == false
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasFollowUp) ...[
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: question.followUpQuestion,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _answers[question.id + 100] ==
                              true; // Store follow-up answer with offset ID
                        },
                      ),
                    ],
                  ],
                ),
            ],
          ),
          isActive: _currentStep == filteredQuestions.indexOf(question) + 1,
          state:
              _currentStep > filteredQuestions.indexOf(question) + 1
                  ? StepState.complete
                  : StepState.indexed,
        );
      }).toList(),
    );

    return steps;
  }

  List<ScreeningQuestion> _getFilteredQuestions() {
    if (_selectedAgeGroup == null) {
      return [_questions.first]; // Only show age question first
    }

    return [
      _questions.first,
      ..._questions.where(
        (q) => q.forAgeGroup == _selectedAgeGroup && !q.isAgeQuestion,
      ),
    ];
  }

  bool _canContinue() {
    if (_currentStep == 0) return true; // Intro screen

    final currentQuestion = _getFilteredQuestions()[_currentStep - 1];
    return _answers.containsKey(currentQuestion.id) ||
        (currentQuestion.isAgeQuestion && _selectedAgeGroup != null);
  }

  void _continue() {
    if (_currentStep < _getFilteredQuestions().length) {
      setState(() => _currentStep += 1);
    } else {
      _showResult();
    }
  }

  void _cancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _setAnswer(int questionId, bool answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _showResult() {
    final isSuspected = _calculateScreeningResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(isSuspected ? "Terduga TB" : "Bukan Terduga TB"),
            content: Text(
              isSuspected
                  ? "Berdasarkan jawaban Anda, terdapat indikasi terduga Tuberkulosis. Silakan berkonsultasi dengan petugas kesehatan untuk pemeriksaan lebih lanjut."
                  : "Berdasarkan jawaban Anda, tidak terdapat indikasi Tuberkulosis. Tetap jaga kesehatan!",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Back to previous screen
                },
                child: Text("Tutup"),
              ),
              if (isSuspected)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to consultation page
                  },
                  child: Text("Konsultasi Petugas"),
                ),
            ],
          ),
    );
  }

  bool _calculateScreeningResult() {
    if (_selectedAgeGroup == null) return false;

    bool suspectedTbc = false;
    final isAdult = _selectedAgeGroup == 1; // >=15

    // Check answers based on age group
    for (var entry in _answers.entries) {
      final questionId = entry.key;
      final answer = entry.value;

      if (questionId == 1) continue; // Skip age question

      if (isAdult) {
        // Adult screening criteria
        if (questionId == 12 && answer == true) {
          final durationDays = _answers[questionId + 100] as int? ?? 0;
          if (durationDays >= 14) suspectedTbc = true; // 2 weeks
        } else if (questionId == 13 && answer == true) {
          suspectedTbc = true; // Coughing blood
        }
      } else {
        // Child screening criteria
        if (questionId == 12 && answer == true) {
          final durationDays = _answers[questionId + 100] as int? ?? 0;
          if (durationDays >= 14) suspectedTbc = true; // 2 weeks
        } else if (questionId == 13 && answer == true) {
          suspectedTbc = true; // Coughing blood
        } else if (questionId == 14 && answer == true) {
          suspectedTbc = true; // Weight loss
        } else if (questionId == 15 && answer == true) {
          suspectedTbc = true; // Fever ≥2 weeks
        } else if (questionId == 16 && answer == true) {
          suspectedTbc = true; // Lethargy
        }
      }
    }

    return suspectedTbc;
  }
}

class ScreeningQuestion {
  final int id;
  final String text;
  final bool isAgeQuestion;
  final int? forAgeGroup; // 0 = <15, 1 = >=15
  final bool followUp;
  final String? followUpQuestion;
  final List<String>? options;

  ScreeningQuestion({
    required this.id,
    required this.text,
    this.isAgeQuestion = false,
    this.forAgeGroup,
    this.followUp = false,
    this.followUpQuestion,
    this.options,
  });
}
