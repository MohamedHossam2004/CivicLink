import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ContentModerationService {
  // Singleton pattern
  static final ContentModerationService _instance = ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  
  // API credentials
  static String apiKey = 'apikey';
  static String baseUrl = 'https://openrouter.ai/api/v1'; 
  
  bool _isInitialized = false;
  
  // Set to true for testing without making actual API calls
  bool testMode = false;
  
  // Test words that will be flagged as hateful in test mode
  final List<String> _testHatefulWords = [
    'hate',
    'stupid',
    'idiot',
    'terrible',
    'worst',
    'kill',
    'death',
  ];

  ContentModerationService._internal() {
    _initFromEnv();
  }
  
  // Initialize from environment variables if available
  void _initFromEnv() {
    try {
      print('Initializing environment variables');
      // Try to load from .env file if it exists
      if (dotenv.isInitialized) {
        final envApiKey = dotenv.maybeGet('OPENAI_API_KEY');
        final envBaseUrl = dotenv.maybeGet('OPENAI_BASE_URL');
        
        if (envApiKey != null && envApiKey.isNotEmpty) {
          apiKey = envApiKey;
        }
        
        if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
          baseUrl = envBaseUrl;
        }
      }
    } catch (e) {
      print('Error loading environment variables: $e');
    }
  }

  /// Initialize the OpenAI client
  void initialize({
    String? apiKeyOverride,
    String? baseUrlOverride,
    String? organization,
    bool? testModeOverride,
  }) {
    if (_isInitialized) return;
    
    if (apiKeyOverride != null && apiKeyOverride.isNotEmpty) {
      apiKey = apiKeyOverride;
    }
    
    if (baseUrlOverride != null && baseUrlOverride.isNotEmpty) {
      baseUrl = baseUrlOverride;
    }
    
    if (testModeOverride != null) {
      testMode = testModeOverride;
    }
    
    // Only initialize OpenAI client if not in test mode
    if (!testMode) {
      OpenAI.apiKey = apiKey;
      OpenAI.baseUrl = baseUrl;
      
      if (organization != null && organization.isNotEmpty) {
        OpenAI.organization = organization;
      }
      
      print('OpenAI client initialized with base URL: $baseUrl');
    } else {
      print('Content moderation service running in TEST MODE');
    }
    
    _isInitialized = true;
  }
  
  /// Check if the client is initialized
  bool get isInitialized => _isInitialized || testMode;
  
  /// Initialize if not already done
  void _ensureInitialized() {
    if (!_isInitialized) {
      initialize();
    }
  }

  /// Check if comment is hateful using OpenAI's moderation API
  /// Returns true if content is flagged as hateful, false otherwise
  Future<bool> isCommentHateful(String commentText) async {
    _ensureInitialized();
    
    // If in test mode, check against test words
    if (testMode) {
      final lowerComment = commentText.toLowerCase();
      for (final word in _testHatefulWords) {
        if (lowerComment.contains(word)) {
          print('TEST MODE: Comment flagged as hateful due to containing: $word');
          return true;
        }
      }
      return false;
    }
    
    try {
      final moderationResponse = await OpenAI.instance.moderation.create(
        input: commentText,
      );

      return moderationResponse.results.first.flagged;
    } catch (e) {
      print('Exception checking for hateful content: $e');
      // In case of API error, we log the error but allow the comment through
      return false;
    }
  }

  /// Check if comment is hateful using custom AI model via direct HTTP
  /// This uses a chat completion with OpenRouter API to detect hateful content
  Future<bool> isCommentHatefulUsingCustomModel(String commentText) async {
    _ensureInitialized();
    
    // If in test mode, use simple word-based check
    if (testMode) {
      final lowerComment = commentText.toLowerCase();
      for (final word in _testHatefulWords) {
        if (lowerComment.contains(word)) {
          print('TEST MODE: Comment flagged as hateful due to containing: $word');
          return true;
        }
      }
      return false;
    }
    
    try {
      // Use direct HTTP request instead of OpenAI client
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://civiclink.app',  // Required for OpenRouter
          'X-Title': 'CivicLink App'  // For OpenRouter analytics
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-v3-base:free',  // Use DeepSeek model
          'messages': [
            {
              'role': 'system',
              'content': 'You are a content moderation AI. Determine if a comment is hateful or not, the comments are in english, arabic, franko arabic. Only respond with "yes" or "no" in english. Example:\nUser: Is this comment hateful? "I hate you because of your race."\nAssistant: yes\n\nUser: Is this comment hateful? "$commentText"'
            },
            {
              'role': 'user',
              'content': 'Is this comment hateful? "$commentText"'
            }
          ],
          'temperature': 0.3,
          'max_tokens': 100
        }),
      );

      print('OpenRouter response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        print('OpenRouter response: ${response.body}');
        
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) {
          final result = content.toString().toLowerCase().trim();
          print('Moderation result: "$result"');
          return result.contains('yes');
        }
      } else {
        print('Error response from OpenRouter: ${response.body}');
      }
      
      // In case of API error, fallback to simple word-based check
      return _fallbackHateSpeechCheck(commentText);
    } catch (e) {
      print('Exception checking for hateful content: $e');
      // Fallback to simple word-based check
      return _fallbackHateSpeechCheck(commentText);
    }
  }
  
  /// Fallback hate speech detection using basic word list
  bool _fallbackHateSpeechCheck(String commentText) {
    final lowerComment = commentText.toLowerCase();
    final hateWords = [
      'hate', 'stupid', 'idiot', 'terrible', 'worst', 'kill', 'death',
      'ugly', 'awful', 'horrible', 'dumb', 'racist', 'sexist'
    ];
    
    for (final word in hateWords) {
      if (lowerComment.contains(word)) {
        print('FALLBACK: Comment flagged as hateful due to containing: $word');
        return true;
      }
    }
    return false;
  }

  /// Show a dialog to inform the user that their comment was flagged as hateful
  Future<void> showHatefulContentAlert(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Comment Not Posted'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Your comment appears to contain hateful or inappropriate content.'),
                SizedBox(height: 8),
                Text('Please revise your comment to ensure it follows community guidelines.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
} 