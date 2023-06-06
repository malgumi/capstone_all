import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/post/WritePostScreen.dart';
import 'package:capstone/screens/post/PostScreen.dart';
import 'package:intl/intl.dart';
import 'package:capstone/drawer.dart';

void main() {
  runApp(MaterialApp(
    title: '구인구직 게시판',
    home: PartyBoardScreen(),
  ));
}

class PartyBoardScreen extends StatefulWidget {
  @override
  FreeBoardScreenState createState() => FreeBoardScreenState();
}

class FreeBoardScreenState extends State<PartyBoardScreen> {
  late Future<List<dynamic>> _jobposts;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredPosts = [];
  List<dynamic> allPosts = [];

  @override
  void initState() {
    super.initState();
    _jobposts = fetchPosts();
  }

  Future<List<dynamic>> fetchPosts() async {
    final response = await http.get(Uri.parse('http://203.247.42.144:443/post/posts?board_id=2'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  void _filterPosts(String keyword) async {
    allPosts = await _jobposts;
    _filteredPosts = allPosts.where((post) {
      final title = post['post_title'].toLowerCase();
      final content = post['post_content'].toLowerCase();
      return title.contains(keyword) || content.contains(keyword);
    }).toList();
    setState(() {
      allPosts;
      _filteredPosts;
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
        setState(() {
          _jobposts = fetchPosts();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
            /*boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],*/
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          '구인구직게시판',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '검색어를 입력하세요',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _filterPosts(_searchController.text);
                  },
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _jobposts,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final jobposts = snapshot.data!;
                    final posts = _searchController.text.isEmpty ? jobposts : _filteredPosts;
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(context, posts[index]);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WritePostScreen(boardId: 2),
            ),
          ).then((value) {
            if (value == true) {
              setState(() {
                _jobposts = fetchPosts();
              });
            }
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xffC1D3FF),
      ),
    );
  }
}