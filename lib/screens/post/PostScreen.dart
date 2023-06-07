import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/post/EditPostScreen.dart';

class PostScreen extends StatefulWidget {
  final dynamic post;

  PostScreen({required this.post});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late Future<List<dynamic>> comments;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _isLoading = false;
  TextEditingController _commentController = TextEditingController();
  double _bottomInset = 0;
  @override
  void initState() {
    super.initState();
    comments = fetchComments();
    _fetchboard();
    _fetchintroduction();
    _checkPostAuthor();
  }

  String? _boardName;
  void _fetchboard() async {
    int board_id = widget.post['board_id'];
    final response = await http
        .get(Uri.parse('http://203.247.42.144:443/post/board?board_id=$board_id'));
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      setState(() {
        _boardName = responseData['rows'][0]['board_name'];

      });
    } else {
      throw Exception('Failed to load board');
    }
  }
  String? _accountIntroduction;
  void _fetchintroduction() async {
    int student_id = widget.post['student_id'];
    final response = await http
        .get(Uri.parse('http://203.247.42.144:443/user/info?student_id=$student_id'));
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);

      setState(() {
        _accountIntroduction = responseData[0]['introduction'];

      });
    } else {
      throw Exception('Failed to load board');
    }
  }
  //댓글 가져오기
  Future<List<dynamic>> fetchComments() async {
    final response = await http.get(Uri.parse(
        'http://203.247.42.144:443/post/comment:?post_id=${widget.post['post_id']}'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  //댓글 입력
  Future<void> postComment(int postId, String content) async {
    final url = Uri.parse('http://203.247.42.144:443/post/commentwrite/${widget.post['post_id']}');
    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 입력에 실패했습니다.(로그인 만료)'), backgroundColor: Colors.red,));
      });
      return;
    }
    final response = await http.post(
      url,
      headers: <String, String>{ //헤더파일 추가
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode( {
        'comment_content': content,
      }),
    );
    if (response.statusCode == 201) {
      // 입력 성공 처리
      // 예시:
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 성공적으로 입력되었습니다.'), backgroundColor: Colors.green,));
      _commentController.clear(); // 댓글 입력 완료 후, TextField를 초기화합니다.
      setState(() {
        comments = fetchComments(); // 댓글 리스트를 다시 불러옵니다.
      });
    } else {
      // 실패 처리
      // 예시:
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 입력에 실패했습니다.'), backgroundColor: Colors.red,));
    }
  }

  //댓글 삭제
  Future<void> _deleteComment(int commentId) async {
    final url = Uri.parse('http://203.247.42.144:443/post/deletecomment/$commentId');
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      setState(() {
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다.(로그인 만료)'), backgroundColor: Colors.red,));
      });
      return;
    }
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 삭제되었습니다.'), backgroundColor: Colors.green,));
      setState(() {
        comments = fetchComments();
      });
    }
    else if (response.statusCode == 300){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 권한이 없습니다.'), backgroundColor: Colors.red,));
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다.'), backgroundColor: Colors.red,));
    }
  }

  //댓글 수정
  Future<void> _editComment(int commentId, String content) async {
    final url = Uri.parse('http://203.247.42.144:443/post/updatecomment/$commentId');
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 수정에 실패했습니다.(로그인 만료)'), backgroundColor: Colors.red,));
      });
      return;
    }
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode( {
        'comment_content': content,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 수정되었습니다.'), backgroundColor: Colors.green,));
      setState(() {
        comments = fetchComments();
      });
    }
    else if (response.statusCode == 300){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 권한이 없습니다.'), backgroundColor: Colors.red,));
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 수정에 실패했습니다.'), backgroundColor: Colors.red,));
    }
  }


//댓글 수정 폼
  void _showEditCommentForm(int commentId, String originalContent) {
    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        final _contentController = TextEditingController(text: originalContent);
        return AlertDialog(
          title: Text('댓글 수정'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: '댓글 내용',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '내용을 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final content = _contentController.text;
                  _editComment(commentId, content);
                  Navigator.of(context).pop();
                }
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }


  void _navigateToEditPostScreen() async{
    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 수정에 실패 했습니다.(로그인 만료)'), backgroundColor: Colors.red,));
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(
          post: widget.post,
        ),
      ),
    ).then((value) {
      // Refresh post data after editing
      setState(() {
        widget.post['post_title'] = value['post_title'];
        widget.post['post_content'] = value['post_content'];
      });
    });
  }
  Future<void> deletePost() async {

    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) { //토쿤
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 삭제에 실패했습니다. (로그인 만료)'), backgroundColor: Colors.red,));
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/post/deletepost/${widget.post['post_id']}'),
      headers: <String, String>{ //헤더파일 추가
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );
    if (response.statusCode == 200) {

    } else {
      throw Exception('Failed to delete post');
    }
  }

  Future<void> reportPost() async{
    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/post/reportPost/${widget.post['post_id']}'),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신고가 접수되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Failed to report Post.');
    }
  }

  String? _profileIntroduction;

  Future<void> _fetchProfile(String studentId) async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/user/info?student_id=$studentId'),
    );
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _profileIntroduction = responseData[0]['introduction'];
      });
    } else {
      throw Exception('Failed to load profile information');
    }
  }
  // 게시글 작성자 여부 확인을 위한 변수
  bool isPostAuthor = false;
  String? Permission;
// 사용자 정보를 가져오고 게시글 작성자인지 확인하는 메서드
  void _checkPostAuthor() async {
    String studentId;
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('게시글 작성에 실패했습니다. (로그인 만료)')));
      });
      return;
    }
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/user/student'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      studentId = responseData[0]['student_id'].toString();
      Permission = responseData[0]['permission'].toString();
      if (studentId == widget.post['student_id'].toString()) {
        setState(() {
          isPostAuthor = true;
        });
      }
      else if(Permission == '2' || Permission == '3'){
        isPostAuthor = true;
      }
    }
    else {
      // Failure
      setState(() {
        final responseData = jsonDecode(response.body);

        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime postDateTime = DateTime.parse(widget.post['post_date']);
    DateTime updatedDateTime = postDateTime.add(Duration(hours: 18));
    return GestureDetector(
      onTap: () {
        // 터치가 발생하면 키보드를 강제로 닫기
        FocusScope.of(context).unfocus();
      },
        child:Scaffold(
      appBar: AppBar(
        title: Text(
          _boardName ?? '',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
        elevation: 0.0,
        actions: [

          if (isPostAuthor) // 게시글 작성자인 경우에만 보여주기
            IconButton(
              onPressed: _navigateToEditPostScreen,
              icon: Icon(Icons.edit),
            ),
          if (isPostAuthor) // 게시글 작성자인 경우에만 보여주기
            IconButton(
              onPressed: () async {
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('게시글 삭제'),
                      content: Text('게시글을 삭제 하시겠습니까?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('취소'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: Text('삭제'),
                          onPressed: () async {
                            await deletePost();
                            Navigator.pop(context, true); // 게시글 삭제 후 true 값을 반환하여 나가도록 함
                          },
                        ),
                      ],
                    );
                  },
                );

                if (confirmDelete == true) {
                  await deletePost();
                  Navigator.pop(context); // true 값을 받은 경우 게시글 삭제 후 나가도록 함
                }
              },
              icon: Icon(Icons.delete),
            ),

        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 13.0),
              Text(
                widget.post['post_title'],
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                widget.post['post_content'],
                style: TextStyle(
                  fontSize: 16.0,
                ),
                //overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () async {
                      bool confirmReport = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('게시글 신고'),
                            content: Text('게시글을 신고 하시겠습니까?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('취소'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: Text('신고'),
                                onPressed: () async {
                                  await reportPost();
                                  Navigator.pop(context, true);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(
                      Icons.flag,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              Divider(
                height: 1.0,
                thickness: 1.0,
                color: Colors.grey[400],
                indent: 0.0,
                endIndent: 0.0,
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  widget.post['board_id'] == 1
                      ? Text(
                    widget.post['student_id'].toString().substring(2, 4) + '학번',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  )
                      : Text(
                    widget.post['student_id'].toString(),
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
              SizedBox(height: 13.0,),
              widget.post['board_id'] == 2
                  ? Text(
                _accountIntroduction ?? '',
                style: TextStyle(color: Colors.grey),
              )
                  : Container(),
              SizedBox(height: 20.0),
              Divider(
                height: 1.0,
                thickness: 1.0,
                color: Colors.grey[400],
                indent: 0.0,
                endIndent: 0.0,
              ),
              SizedBox(height: 16.0),
              FutureBuilder<List<dynamic>>(
                future: comments,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {

                    if (snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          '등록된 댓글이 없습니다.',
                          style: TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          DateTime commetDateTime = DateTime.parse(snapshot.data![index]['comment_date']);
                          DateTime commetupdatedDateTime = commetDateTime.add(Duration(hours: 9));
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                widget.post['board_id'] == 1 || widget.post['board_id'] == 4
                                    ? Text(
                                  snapshot.data![index]['student_id'].toString().substring(2, 4) + '학번',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : GestureDetector(
                                  onTap: () {
                                    final studentId = snapshot.data![index]['student_id'].toString();
                                    _fetchProfile(studentId).then((_) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('프로필 보기'),
                                            content: Text(_profileIntroduction ?? '프로필 내용이 없습니다.'),
                                            actions: [
                                              TextButton(
                                                child: Text('닫기'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      SizedBox(width: 5),
                                      Text(
                                        snapshot.data![index]['student_id'].toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        snapshot.data![index]['comment_content'].toString(),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined),
                                      iconSize: 18,
                                      color: Colors.grey,
                                      onPressed: () => _showEditCommentForm(snapshot.data![index]['comment_id'], snapshot.data![index]['comment_content']),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.cancel_outlined),
                                      iconSize: 18,
                                      color: Colors.grey,
                                      onPressed: () async {
                                        bool confirmDelete = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('댓글 삭제'),
                                              content: Text('댓글을 삭제 하시겠습니까?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text('취소'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop(false);
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text('삭제'),
                                                  onPressed: (){
                                                    _deleteComment(snapshot.data![index]['comment_id']);
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirmDelete == true) {
                                          _deleteComment(snapshot.data![index]['comment_id']);
                                        }
                                      },
                                    ),

                                  ],
                                ),

                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm:ss').format(commetupdatedDateTime),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                Divider(),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '댓글을 불러오는 중 오류가 발생했습니다. ${snapshot.error}',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      bottomSheet: Container(
        padding: EdgeInsets.only(bottom: _bottomInset),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: '댓글을 입력해주세요.',
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                ),
                onEditingComplete: () {
                  setState(() {
                    _bottomInset = 0;
                  });
                },
              ),
            ),
              IconButton(
                onPressed: () {
                  if (_commentController.text.isNotEmpty) {
                    final content = _commentController.text;
                    final postId = widget.post['post_id'];
                    postComment(postId, content);
                  }
                },
                icon: Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );


  }
}
