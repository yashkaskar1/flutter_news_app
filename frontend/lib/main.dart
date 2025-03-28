import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(NewsApp());
}

class NewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: NewsScreen(),
    );
  }
}

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List articles = [];
  bool isLoading = true;
  String selectedCategory = 'general'; // Default category

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final response = await http.get(Uri.parse("http://127.0.0.1:8000/articles?category=$selectedCategory"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          articles = data["articles"];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News App', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          DropdownButton<String>(
            dropdownColor: Colors.black,
            value: selectedCategory,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedCategory = newValue;
                  isLoading = true;
                });
                fetchNews();
              }
            },
            items: ['general', 'business', 'entertainment', 'health', 'science', 'sports', 'technology']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value.toUpperCase(), style: TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return NewsCard(article: articles[index]);
        },
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final Map<String, dynamic> article;

  NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    String? imageUrl = article['urlToImage'];

    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset("assets/placeholder.png", height: 200, width: double.infinity, fit: BoxFit.cover);
              },
            )
                : Image.asset("assets/placeholder.png", height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 5),
                Text(article['description'] ?? 'No description available', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: Text("Read More", style: TextStyle(color: Colors.blueAccent)),
                      onPressed: () => _openArticle(article['url']),
                    ),
                    TextButton(
                      child: Text("Recommendations", style: TextStyle(color: Colors.greenAccent)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecommendationsScreen(articleId: article['id']),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openArticle(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class RecommendationsScreen extends StatefulWidget {
  final int articleId;
  RecommendationsScreen({required this.articleId});

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List recommendedArticles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    try {
      final response = await http.get(Uri.parse("http://127.0.0.1:8000/recommend/${widget.articleId}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recommendedArticles = data;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recommended Articles')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: recommendedArticles.length,
        itemBuilder: (context, index) {
          return NewsCard(article: recommendedArticles[index]);
        },
      ),
    );
  }
}
