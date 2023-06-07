import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:capstone/drawer.dart';

void main() async{
  final selectedMenu = 5; // 원하는 _selectedMenu 값으로 설정

  runApp(MaterialApp(
    title: '1학년 공지',
    home: NoticeTalkScreen_1(boardId: selectedMenu),
  ));
}

class ChatBubble extends CustomPainter {
  final Color color;
  final Alignment alignment;

  ChatBubble({
    required this.color,
    required this.alignment,
  });

  var _radius = 10.0;
  var _x = 10.0;
  var _y = 20.0;
  var _borderWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    var path = Path();
    path.addRRect(
      RRect.fromLTRBAndCorners(
        _x,
        0,
        size.width,
        size.height,
        bottomRight: Radius.circular(_radius),
        bottomLeft: Radius.circular(_radius),
        topRight: Radius.circular(_radius),
        topLeft: Radius.circular(_radius),
      ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = this.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );
    var clipPath = Path();
    clipPath.moveTo(0, 0);//여기가 최좌단 꼭짓점
    clipPath.lineTo(_x, (size.height/10));
    clipPath.lineTo(_x, _y);//위쪽 꼭짓점
    canvas.clipPath(clipPath);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0,
        0.0,
        _x,
        size.height,
        topRight: Radius.circular(_radius),
      ),
      Paint()
        ..color = this.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class NoticeTalkScreen_1 extends StatefulWidget {
  final int boardId;

  const NoticeTalkScreen_1({Key? key, required this.boardId}) : super(key: key);

  @override
  NoticeTalkScreenState createState() => NoticeTalkScreenState(boardId: boardId);
}


class NoticeTalkScreenState extends State<NoticeTalkScreen_1> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _noticeController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  late Future<List<dynamic>> noticesAll;
  late Future<List<dynamic>> notices1;
  late Future<List<dynamic>> notices2;
  late Future<List<dynamic>> notices3;
  late Future<List<dynamic>> notices4;

  late int _selectedMenu; // non-nullable 형식으로 변경

  NoticeTalkScreenState({required int boardId}) : _selectedMenu = boardId;

  @override
  void dispose() {
    _titleController.dispose();
    _noticeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedMenu = widget.boardId; // boardId 값으로 _selectedMenu 초기화
    studentInfo();
    noticesAll = fetchNoticesAll();
    notices1 = fetchNotices1();
    notices2 = fetchNotices2();
    notices3 = fetchNotices3();
    notices4 = fetchNotices4();
  }

  // 권한받아오기
  int? _permission;
  void studentInfo() async {
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성에 실패했습니다. (로그인 만료)')),
        );
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
      // Success
      final responseData = jsonDecode(response.body);
      setState(() {
        _permission = responseData[0]['permission'];
        _isLoading = false; //임의추가
      });
    } else {
      // Failure
      setState(() {
        final responseData = jsonDecode(response.body);
        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }

  // 글 작성
  void _submitForm() async {
    if (_formKey.currentState?.validate() == false) return;
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 작성에 실패했습니다. (로그인 만료)')),
        );
      });
      return;
    }

    int board_id = _selectedMenu;

    if (_selectedMenu == 1) {
      board_id = 3; // Set board_id as 5 for noticesAll
    } else if (_selectedMenu == 2) {
      board_id = 5; // Set board_id as 6 for notices1
    } else if (_selectedMenu == 3) {
      board_id = 6; // Set board_id as 7 for notices2
    } else if (_selectedMenu == 4) {
      board_id = 7; // Set board_id as 8 for notices3
    } else {
      board_id = 8; // Set board_id as 3 for notices4
    }

    final Map<String, dynamic> postData = {
      'board_id': board_id,
      'post_title': _titleController.text,
      'post_content': '',
      'post_file': 'null', // TODO: Implement file uploading
    };

    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/post/write'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode(postData),
    );

    if (response.statusCode == 201) {
      // Success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NoticeTalkScreen_1(boardId: _selectedMenu),
        ),
      );
    } else {
      // Failure
      final responseData = jsonDecode(response.body);
      setState(() {
        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }


  // 서버로부터 게시글 목록을 가져옴
  Future<List<dynamic>> fetchNotices1() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/posts?board_id=5'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> notice = jsonDecode(response.body);
      return notice;
    } else {
      throw Exception('Failed to load notices');
    }
  }

  Future<List<dynamic>> fetchNoticesAll() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/posts?board_id=3'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> notice = jsonDecode(response.body);
      return notice;
    } else {
      throw Exception('Failed to load notices');
    }
  }

  Future<List<dynamic>> fetchNotices2() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/posts?board_id=6'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> notice = jsonDecode(response.body);
      return notice;
    } else {
      throw Exception('Failed to load notices');
    }
  }

  Future<List<dynamic>> fetchNotices3() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/posts?board_id=7'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> notice = jsonDecode(response.body);
      return notice;
    } else {
      throw Exception('Failed to load notices');
    }
  }

  Future<List<dynamic>> fetchNotices4() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/posts?board_id=8'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> notice = jsonDecode(response.body);
      return notice;
    } else {
      throw Exception('Failed to load notices');
    }
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
          '공지 알림톡',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xffC1D3FF),
      ),
      backgroundColor: Colors.white,

      body: Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _selectedMenu == 1
                    ? noticesAll
                    : _selectedMenu == 2
                    ? notices1
                    : _selectedMenu == 3
                    ? notices2
                    : _selectedMenu == 4
                    ? notices3
                    : notices4,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final notices = snapshot.data!;
                    return ListView.builder(
                      reverse: true,
                      itemCount: notices.length,
                      itemBuilder: (BuildContext context, int index) {
                        dynamic notice = notices[index];
                        return buildNoticeItem(context, notice);
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
            SizedBox(height: 8.0),
            Divider(
              height: 1.0,
              thickness: 1.0,
              color: Colors.grey[400],
              indent: 0.0,
              endIndent: 0.0,
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 30), // 상단 패딩: 8.0, 하단 패딩: 0, 좌우 패딩: 16.0
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Align buttons with equal spacing
                children: [
                  TextButton(
                    child: Text('전체'),
                    style: TextButton.styleFrom(
                      primary: _selectedMenu == 1 ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedMenu = 1;
                      });
                    },
                  ),
                  TextButton(
                    child: Text('1학년'),
                    style: TextButton.styleFrom(
                      primary: _selectedMenu == 2 ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedMenu = 2;
                      });
                    },
                  ),
                  TextButton(
                    child: Text('2학년'),
                    style: TextButton.styleFrom(
                      primary: _selectedMenu == 3 ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedMenu = 3;
                      });
                    },
                  ),
                  TextButton(
                    child: Text('3학년'),
                    style: TextButton.styleFrom(
                      primary: _selectedMenu == 4 ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedMenu = 4;
                      });
                    },
                  ),
                  TextButton(
                    child: Text('4학년'),
                    style: TextButton.styleFrom(
                      primary: _selectedMenu == 5 ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedMenu = 5;
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(6.0, 0, 6.0, 15),
              child: buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNoticeItem(BuildContext context, dynamic post) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          child: CustomPaint(
            painter: ChatBubble(
              color: Color(0xffC1D3FF),
              alignment: Alignment.topLeft,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10.0, top: 5.0),
                    child: Text(
                      post['post_title'],
                      style: TextStyle(
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm:ss').format(
                            DateTime.parse(post['post_date']),
                          ),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextComposer() {
    if (_permission == 1) {
      return SizedBox.shrink();
    } else {
      return IconTheme(
        data: IconThemeData(color: Theme.of(context).accentColor),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  maxLines: null,
                  controller: _titleController,
                  decoration: InputDecoration.collapsed(hintText: '메시지 보내기'),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isLoading
                      ? null
                      : () {
                    _submitForm();
                    _noticeController.clear();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}



