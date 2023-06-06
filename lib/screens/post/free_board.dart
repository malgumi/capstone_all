import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/post/PostScreen.dart';
import 'package:capstone/screens/post/WritePostScreen.dart';
import 'package:intl/intl.dart';
import 'package:capstone/drawer.dart';
void main() {
  runApp(MaterialApp(
    title: '자유게시판 앱',
    home: FreeBoardScreen(),
  ));
}

class FreeBoardScreen extends StatefulWidget {
  @override
  FreeBoardScreenState createState() => FreeBoardScreenState();
}

class FreeBoardScreenState extends State<FreeBoardScreen> {
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
    final response = await http
        .get(Uri.parse('http://203.247.42.144:443/post/posts?board_id=1'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  //댓글 갯수 표시 기능 구현중
  Future _fetchCommentsCount() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/commentsAll'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load comments count');
    }
  }

  void filterPosts(String keyword) async {
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
      onTap: () async {
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
                    DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(updatedDateTime),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                  //댓글 갯수 표시 기능 구현중
                  // StreamBuilder(
                  //   stream: _fetchCommentsCount().asStream(),
                  //   builder: (context, snapshot) {
                  //     if (snapshot.hasData) {
                  //       final comments = snapshot.data;
                  //       int commentCount = 0;
                  //       if (comments is List) {
                  //         final matchingComments = comments?.where((comment) => comment['post_id'] == post['post_id']);
                  //         if (matchingComments != null && matchingComments.isNotEmpty) {
                  //           commentCount = matchingComments.first['comment_count'];
                  //         }
                  //       }
                  //       return Text(
                  //         '댓글 $commentCount',
                  //         style: TextStyle(
                  //           fontSize: 14.0,
                  //           color: Colors.grey,
                  //         ),
                  //       );
                  //     } else {
                  //       return Text(
                  //         '로딩 중...',
                  //         style: TextStyle(
                  //           fontSize: 14.0,
                  //           color: Colors.grey,
                  //         ),
                  //       );
                  //     }
                  //   },
                  // ),
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
          '자유게시판',
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
                    filterPosts(_searchController.text);
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
                    return ListView.builder(
                      itemCount: filterposts.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(context, filterposts[index]);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WritePostScreen(boardId: 1),
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
