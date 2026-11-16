import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/word.dart';

/// Источник данных для загрузки слов из файла assets/words.json.
class AssetWordsSource {
  static const String defaultAssetPath = 'assets/words.json';

  final AssetBundle _bundle;
  final String assetPath;

  AssetWordsSource({
    AssetBundle? bundle,
    this.assetPath = defaultAssetPath,
  }) : _bundle = bundle ?? rootBundle;

  /// Загружает и парсит все слова из JSON в assets.
  Future<List<Word>> loadWords() async {
    final response = await _bundle.loadString(assetPath);
    final List<dynamic> data = jsonDecode(response) as List<dynamic>;
    return data
        .map((json) => Word.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
