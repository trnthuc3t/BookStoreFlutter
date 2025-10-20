class Message {
  String content;
  bool isFromUser;
  int timestamp;

  Message({
    required this.content,
    required this.isFromUser,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'] ?? '',
      isFromUser: json['isFromUser'] ?? false,
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isFromUser': isFromUser,
      'timestamp': timestamp,
    };
  }

  Message copyWith({
    String? content,
    bool? isFromUser,
    int? timestamp,
  }) {
    return Message(
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
