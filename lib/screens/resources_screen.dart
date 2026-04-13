import 'package:flutter/material.dart';
import '../models/resource_model.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final List<Map<String, String>> _englishResources = [
    {'title': 'The Power of Atomic Habits', 'category': 'Productivity'},
    {'title': 'Mindfulness and Meditation Guide', 'category': 'Mental Health'},
    {'title': 'Deep Work: Staying Focused', 'category': 'Focus'},
    {'title': 'Digital Detox: 7 Day Challenge', 'category': 'Well-being'},
    {'title': 'Time Management Mastery', 'category': 'Efficiency'},
    {'title': 'Building Emotional Resilience', 'category': 'Psychology'},
    {'title': 'The Art of Saying No', 'category': 'Self-care'},
    {'title': 'Morning Routines for Success', 'category': 'Routine'},
    {'title': 'Overcoming Procrastination', 'category': 'Motivation'},
    {'title': 'Healthy Work-Life Balance', 'category': 'Lifestyle'},
    {'title': 'The Science of Better Sleep', 'category': 'Health'},
    {'title': 'Creative Thinking Techniques', 'category': 'Creativity'},
    {'title': 'Effective Communication Skills', 'category': 'Growth'},
    {'title': 'Goal Setting for the Future', 'category': 'Planning'},
    {'title': 'Financial Mindset Basics', 'category': 'Finance'},
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateFetch();
  }

  Future<void> _simulateFetch() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9181F4)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _simulateFetch();
      },
      color: const Color(0xFF9181F4),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _englishResources.length,
        itemBuilder: (_, i) => _ResourceTile(
          title: _englishResources[i]['title']!,
          category: _englishResources[i]['category']!,
          index: i + 1,
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final String title;
  final String category;
  final int index;
  const _ResourceTile({required this.title, required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF9181F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF9181F4), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9181F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9181F4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '5 min read',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE0E0E0), size: 14),
        ],
      ),
    );
  }
}
