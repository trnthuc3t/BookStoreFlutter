class Author {
  final int id;
  final String penName;
  final String? createdAt;
  final int bookCount;

  Author({
    required this.id,
    required this.penName,
    this.createdAt,
    this.bookCount = 0,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? 0,
      penName: json['pen_name'] ?? '',
      createdAt: json['created_at'],
      bookCount: json['book_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pen_name': penName,
      'created_at': createdAt,
      'book_count': bookCount,
    };
  }

  // Get initials for avatar display
  String getInitials() {
    if (penName.isEmpty) return '?';
    final words = penName.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[words.length - 1].substring(0, 1)}'.toUpperCase();
  }
}
