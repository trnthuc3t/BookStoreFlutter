import 'package:flutter/material.dart';
import '../models/author.dart';

class AuthorsGridWidget extends StatelessWidget {
  final List<Author> authors;
  final Function(Author) onAuthorTap;

  const AuthorsGridWidget({
    super.key,
    required this.authors,
    required this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: authors.length,
      itemBuilder: (context, index) {
        final author = authors[index];
        return _buildAuthorCard(context, author);
      },
    );
  }

  Widget _buildAuthorCard(BuildContext context, Author author) {
    return GestureDetector(
      onTap: () => onAuthorTap(author),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getGradientColors(author.id),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    author.getInitials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              
              // Author name
              Flexible(
                child: Text(
                  author.penName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generate gradient colors based on author ID for variety
  List<Color> _getGradientColors(int id) {
    final colorSets = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Orange
      [const Color(0xFF30cfd0), const Color(0xFF330867)], // Teal
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // Light
      [const Color(0xFFff9a9e), const Color(0xFFfecfef)], // Rose
    ];

    return colorSets[id % colorSets.length];
  }
}
