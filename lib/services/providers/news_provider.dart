import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../model/news_article.dart';

class NewsProvider extends ChangeNotifier {
  static const String _newsBoxName = 'news_cache';
  static const String _newsListKey = 'news_list';
  static const String _newsLastFetchKey = 'news_last_fetch';
  static const String _apiUrl =
      'https://newsapi.org/v2/everything?q=%28crypto%20OR%20cryptocurrency%20OR%20bitcoin%20OR%20ethereum%20OR%20blockchain%29&domains=coindesk.com,cointelegraph.com,bloomberg.com,theverge.com,wsj.com,reuters.com&language=en&sortBy=publishedAt&apiKey=d81b74770f9f450d9c32a54210cbe09e';

  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String? _error;

  List<NewsArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  NewsProvider() {
    _isLoading = false;
    fetchNewsIfNeeded();
  }

  Future<void> fetchNewsIfNeeded() async {
    _isLoading = false;
    notifyListeners();
    final box = await Hive.openBox(_newsBoxName);
    final lastFetch = box.get(_newsLastFetchKey) as int?;
    final now = DateTime.now();
   
    final shouldFetch = true;
    print(
        '[DEBUG] fetchNewsIfNeeded called, shouldFetch=$shouldFetch, lastFetch=$lastFetch');
    if (shouldFetch) {
      try {
        final response = await http.get(Uri.parse(_apiUrl));
        print('[DEBUG] NewsAPI status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> articlesJson = data['articles'] ?? [];
          print('[DEBUG] NewsAPI articles count: ${articlesJson.length}');
          _articles = articlesJson
              .take(5)
              .map((json) => NewsArticle.fromJson(json))
              .toList();
          print('[DEBUG] Parsed articles count: ${_articles.length}');
          if (_articles.isNotEmpty) {
            print('[DEBUG] First article title: ${_articles[0].title}');
          }
          await box.put(
              _newsListKey, _articles.map((a) => a.toJson()).toList());
          await box.put(_newsLastFetchKey, now.millisecondsSinceEpoch);
          _error = null;
        } else {
          _error = 'Failed to fetch news: ${response.statusCode}';
          _articles = [];
        }
      } catch (e, stack) {
        print('[DEBUG] Error parsing news: $e');
        print(stack);
        _error = 'Error: $e';
        _articles = [];
      }
    } else
      _isLoading = false;
    notifyListeners();
  }

  Future<void> forceRefresh() async {
    final box = await Hive.openBox(_newsBoxName);
    await box.delete(_newsLastFetchKey);
    await fetchNewsIfNeeded();
  }
}
