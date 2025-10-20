class Feedback {
  int id;
  String? content;
  String? message; // Alias for content
  double rate;
  String? userEmail;
  String? dateTime;
  DateTime? timestamp; // For easier date handling
  bool isRead;

  Feedback({
    this.id = 0,
    this.content,
    this.message,
    this.rate = 0.0,
    this.userEmail,
    this.dateTime,
    this.timestamp,
    this.isRead = false,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? 0,
      content: json['content'],
      message: json['message'] ?? json['content'],
      rate: (json['rate'] ?? 0.0).toDouble(),
      userEmail: json['userEmail'],
      dateTime: json['dateTime'],
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'message': message,
      'rate': rate,
      'userEmail': userEmail,
      'dateTime': dateTime,
      'timestamp': timestamp?.toIso8601String(),
      'isRead': isRead,
    };
  }

  Feedback copyWith({
    int? id,
    String? content,
    String? message,
    double? rate,
    String? userEmail,
    String? dateTime,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return Feedback(
      id: id ?? this.id,
      content: content ?? this.content,
      message: message ?? this.message,
      rate: rate ?? this.rate,
      userEmail: userEmail ?? this.userEmail,
      dateTime: dateTime ?? this.dateTime,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
