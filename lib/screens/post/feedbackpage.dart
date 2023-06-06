import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/post/PostScreen.dart';
import 'package:capstone/screens/post/WritePostScreen.dart';
import 'package:intl/intl.dart';
import 'package:capstone/drawer.dart';
void main() {
  runApp(MaterialApp(
    title: '피드백',
    home: FeedBackScreen(),
  ));
}

class FeedBackScreen extends StatefulWidget {
  @override
  _FeedBackScreenState createState() => _FeedBackScreenState();
}

class _FeedBackScreenState extends State<FeedBackScreen> {
  late Future<List<dynamic>> _posts;
  late Future<List<dynamic>> _reportPosts;
  List<dynamic> allPosts = [];

  @override
  void initState() {
    super.initState();
    _posts = _fetchPosts();
    _reportPosts = _fetchReportPosts();
  }

  Future<List<dynamic>> _fetchPosts() async {
    final response = await http.get(Uri.parse('http://203.247.42.144:443/post/posts?board_id=90'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<List<dynamic>> _fetchReportPosts() async {
    final response = await http.get(Uri.parse('http://203.247.42.144:443/post/getReport'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts = _fetchPosts();
    });
  }

  Future<void> _refreshReportPosts() async {
    setState(() {
      _reportPosts = _fetchReportPosts();
    });
  }

  Widget _buildPostItem(BuildContext context, dynamic post) {
    DateTime postDateTime = DateTime.parse(post['post_date']);
    DateTime updatedDateTime = postDateTime.add(Duration(hours: 18));
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostScreen(post: post),
          ),
        );
        _refreshPosts();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
            border: Border.all(
              width: 2,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['post_title'],
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                post['post_content'],
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    post['student_id'].toString(),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(updatedDateTime),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContainer(Widget child, VoidCallback onPressed) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            '피드백',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xffC1D3FF),
          centerTitle: true,
          elevation: 0.0,
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: '피드백',
              ),
              Tab(
                text: '신고 게시글',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _refreshPosts,
              child: FutureBuilder<List<dynamic>>(
                future: _posts,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final posts = snapshot.data!;
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(context, posts[index]);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('${snapshot.error}'),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: _refreshReportPosts,
              child: FutureBuilder<List<dynamic>>(
                future: _reportPosts,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final reportPosts = snapshot.data!;
                    return ListView.builder(
                      itemCount: reportPosts.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(context, reportPosts[index]);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('${snapshot.error}'),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
