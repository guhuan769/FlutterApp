// security_questions.dart
class SecurityQuestion {
  final String question;
  final String answer;

  SecurityQuestion({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
  };

  factory SecurityQuestion.fromJson(Map<String, dynamic> json) => SecurityQuestion(
    question: json['question'],
    answer: json['answer'],
  );
}

class UserSecurityInfo {
  final String realName;
  final String birthDate;

  UserSecurityInfo({
    required this.realName,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() => {
    'realName': realName,
    'birthDate': birthDate,
  };

  factory UserSecurityInfo.fromJson(Map<String, dynamic> json) => UserSecurityInfo(
    realName: json['realName'],
    birthDate: json['birthDate'],
  );
}