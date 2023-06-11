import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/post/WritePostScreen.dart';
import 'package:capstone/screens/post/PostScreen.dart';
import 'package:intl/intl.dart';
import 'package:capstone/drawer.dart';

void main() {
  runApp(MaterialApp(
    title: 'Q&A게시판',
    home: QnABoardScreen(),
  ));
}

class QnABoardScreen extends StatefulWidget {
  @override
  QnABoardScreenState createState() => QnABoardScreenState();
}

class QnABoardScreenState extends State<QnABoardScreen> {
  late Future<List<dynamic>> _posts;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredPosts = [];
  List<dynamic> allPosts = [];

  @override
  void initState() {
    super.initState();
    _posts = fetchPosts();
  }

  Future<List<dynamic>> fetchPosts() async {
    final response = await http.get(Uri.parse('http://203.247.42.144:443/post/posts?board_id=4'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  void _filterPosts(String keyword) async {
    allPosts = await _posts;
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
      onTap: () async{
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostScreen(post: post),
          ),
        );
        setState(() {
          _posts = fetchPosts();
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
                    post['student_id'].toString().substring(2, 4) + '학번',
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
          'Q&A게시판',
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
                future: _posts,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final posts = snapshot.data!;
                    final filterposts = _searchController.text.isEmpty ? posts : _filteredPosts;
                    final int index81 = posts.indexWhere((post) => post['post_id'] == 385);
                    // FAQ 게시물을 찾아서 해당 게시물을 리스트의 맨 앞으로 이동
                    if (index81 != -1) {
                      final post81 = posts.removeAt(index81);
                      posts.insert(0, post81);
                    }
                    return ListView.builder(
                      itemCount: filterposts.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(context, filterposts[index]);
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
              builder: (context) => WritePostScreen(boardId: 4),
            ),
          ).then((value) {
            if (value == true) {
              setState(() {
                _posts = fetchPosts();
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