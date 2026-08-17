import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Article {
  final String title;
  final String category;
  final String imageUrl;
  final String sourceUrl;
  final String date;

  Article({
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.sourceUrl,
    required this.date,
  });
}

class NewsRepository {
  static final NewsRepository _instance = NewsRepository._internal();
  factory NewsRepository() => _instance;
  NewsRepository._internal();

  List<Article>? _cachedArticles;
  DateTime? _lastFetch;

  Future<List<Article>> fetchNutritionNews({int offset = 0, bool refresh = false}) async {
    // ponytail: In-memory cache for 15 minutes to save bandwidth and API calls
    if (!refresh && offset == 0 && _cachedArticles != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inMinutes < 15) {
        return _cachedArticles!;
      }
    }

    try {
      final page = (offset ~/ 15) + 1;
      final url = Uri.parse(
        'https://newsapi.org/v2/everything?q=nutrisi OR kesehatan OR nutrition&language=id&pageSize=15&page=$page&apiKey=121ad7595f7e494ea8e18de894f92ceb',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articlesRaw = data['articles'] as List? ?? [];

        final newArticles = articlesRaw.map((raw) {
          final String title = raw['title'] ?? 'No Title';
          final String image = raw['urlToImage'] ?? '';
          final String link = raw['url'] ?? '';
          final String sourceName = raw['source']?['name'] ?? 'Artikel';

          String dateStr = 'Terbaru';
          final String publishedAt = raw['publishedAt'] ?? '';
          if (publishedAt.isNotEmpty) {
            try {
              final date = DateTime.parse(publishedAt);
              dateStr = '${date.day}/${date.month}/${date.year}';
            } catch (_) {}
          }

          return Article(
            title: title,
            category: sourceName.toUpperCase(),
            imageUrl: image,
            sourceUrl: link,
            date: dateStr,
          );
        }).toList();

        if (offset == 0) {
          _cachedArticles = newArticles;
        } else {
          _cachedArticles?.addAll(newArticles);
        }
        _lastFetch = DateTime.now();
        return _cachedArticles!;
      }
      return [];
    } catch (e) {
      print('Error fetching news: $e');
      return _cachedArticles ?? [];
    }
  }
}
