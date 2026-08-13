import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../config/constants.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../services/hive_service.dart';

enum QuizMode { practice, exam }

class QuizProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Course? _activeCourse;
  Course? get activeCourse => _activeCourse;

  QuizMode _mode = QuizMode.practice;
  QuizMode get mode => _mode;

  List<Question> _questions = [];
  List<Question> get questions => _questions;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _soundOn = true;
  bool get soundOn => _soundOn;
  void setSoundOn(bool value) {
    _soundOn = value;
  }

  // Practice Mode
  int? _selectedOptionIndex;
  int? get selectedOptionIndex => _selectedOptionIndex;

  bool _isAnswerChecked = false;
  bool get isAnswerChecked => _isAnswerChecked;

  int _sessionCorrectAnswers = 0;
  int get sessionCorrectAnswers => _sessionCorrectAnswers;

  int _sessionAttempted = 0;
  int get sessionAttempted => _sessionAttempted;

  // Combo system
  int _currentCombo = 0;
  int get currentCombo => _currentCombo;

  int _sessionBestCombo = 0;
  int get sessionBestCombo => _sessionBestCombo;

  bool _lastAnswerCorrect = false;
  bool get lastAnswerCorrect => _lastAnswerCorrect;

  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;

  // Hint system
  bool _hintUsedThisQuestion = false;
  bool get hintUsedThisQuestion => _hintUsedThisQuestion;
  List<int> _eliminatedOptions = [];
  List<int> get eliminatedOptions => _eliminatedOptions;

  // Exam Mode
  final Map<int, int> _examAnswers = {};
  Map<int, int> get examAnswers => _examAnswers;

  int _examDurationSeconds = AppConstants.examDefaultMinutes * 60;
  int _examRemainingSeconds = AppConstants.examDefaultMinutes * 60;
  int get examRemainingSeconds => _examRemainingSeconds;

  Timer? _examTimer;
  bool get isExamRunning => _examTimer != null && _examTimer!.isActive;

  Future<void> startSession({
    required Course course,
    required QuizMode mode,
    List<Question>? overrideQuestions,
    int examDurationMinutes = 30,
    bool soundOn = true,
  }) async {
    _isLoading = true;
    _activeCourse = course;
    _mode = mode;
    _soundOn = soundOn;
    _currentIndex = 0;
    _selectedOptionIndex = null;
    _isAnswerChecked = false;
    _sessionCorrectAnswers = 0;
    _sessionAttempted = 0;
    _currentCombo = 0;
    _sessionBestCombo = 0;
    _lastAnswerCorrect = false;
    _sessionStartTime = DateTime.now();
    _eliminatedOptions = [];
    _hintUsedThisQuestion = false;
    _examAnswers.clear();
    _examRemainingSeconds = examDurationMinutes * 60;
    _examDurationSeconds = examDurationMinutes * 60;

    _cancelTimer();
    notifyListeners();

    if (overrideQuestions != null && overrideQuestions.isNotEmpty) {
      _questions = overrideQuestions.map((q) => Question.shuffled(q)).toList()..shuffle();
    } else {
      final localQuestions = _hiveService.getCachedQuestions(course.id);
      if (localQuestions.isNotEmpty) {
        _questions = localQuestions.map((q) => Question.shuffled(q)).toList()..shuffle();
      } else {
        _questions = [];
      }
    }

    if (_mode == QuizMode.exam && _questions.length > AppConstants.examMaxQuestions) {
      _questions = _questions.sublist(0, AppConstants.examMaxQuestions);
    } else if (_mode == QuizMode.practice) {
      if (_questions.length > AppConstants.practiceMaxQuestions) {
        _questions = _questions.sublist(0, AppConstants.practiceMaxQuestions);
      }
    }

    _isLoading = false;
    notifyListeners();

    if (_mode == QuizMode.exam) {
      _startExamTimer();
    }
  }

  Question? get currentQuestion {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return null;
    return _questions[_currentIndex];
  }

  void selectOption(int index) {
    if (_mode == QuizMode.practice) {
      if (_isAnswerChecked) return;
      _selectedOptionIndex = index;
    } else {
      _examAnswers[_currentIndex] = index;
    }
    notifyListeners();
  }

  Future<void> checkAnswer() async {
    if (_mode != QuizMode.practice || _isAnswerChecked || _selectedOptionIndex == null) return;
    final q = currentQuestion;
    if (q == null) return;

    _isAnswerChecked = true;
    _sessionAttempted++;

    final correct = q.correctIndex;
    final isCorrect = _selectedOptionIndex == correct;
    _lastAnswerCorrect = isCorrect;

    if (isCorrect) {
      _sessionCorrectAnswers++;
      _currentCombo++;
      if (_currentCombo > _sessionBestCombo) {
        _sessionBestCombo = _currentCombo;
      }
    } else {
      _currentCombo = 0;
    }
    notifyListeners();

    if (_soundOn) {
      _playAssetSound(isCorrect ? 'sounds/correct.wav' : 'sounds/wrong.wav');
    }
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedOptionIndex = null;
      _isAnswerChecked = false;
      _eliminatedOptions = [];
      _hintUsedThisQuestion = false;
      notifyListeners();
    }
  }

  void useHint() {
    if (_mode != QuizMode.practice || _isAnswerChecked || _hintUsedThisQuestion) return;
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;

    final correctIdx = _questions[_currentIndex].correctIndex;
    final options = List<int>.generate(_questions[_currentIndex].options.length, (i) => i);
    options.remove(correctIdx);

    final toEliminate = (options.length / 2).ceil();
    options.shuffle();
    _eliminatedOptions = options.sublist(0, toEliminate);
    _hintUsedThisQuestion = true;
    notifyListeners();
  }

  // Exam Mode
  void navigateToQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void _startExamTimer() {
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_examRemainingSeconds > 0) {
        _examRemainingSeconds--;
        notifyListeners();
      } else {
        _cancelTimer();
        notifyListeners();
      }
    });
  }

  void _cancelTimer() {
    _examTimer?.cancel();
    _examTimer = null;
  }

  Map<String, dynamic> submitExam() {
    _cancelTimer();
    int correctCount = 0;

    for (int i = 0; i < _questions.length; i++) {
      final selected = _examAnswers[i];
      final actualCorrect = _questions[i].correctIndex;
      if (selected == actualCorrect) {
        correctCount++;
      }
    }

    final scorePercentage = _questions.isEmpty
        ? 0
        : ((correctCount / _questions.length) * 100).round();

    return {
      'totalQuestions': _questions.length,
      'correctAnswers': correctCount,
      'scorePercentage': scorePercentage,
      'timeSpentSeconds': _examDurationSeconds - _examRemainingSeconds,
    };
  }

  Future<void> _playAssetSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    _audioPlayer.dispose();
    super.dispose();
  }
}
