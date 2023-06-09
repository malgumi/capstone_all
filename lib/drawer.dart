import 'package:capstone/screens/completion/completed_subject_select.dart';
import 'package:capstone/screens/completion/graduation_guide.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/gScore/gscore_myscore.dart';
import 'package:capstone/screens/gScore/gscore_admin_check.dart';
import 'package:capstone/screens/login/adminsingup.dart';
import 'package:capstone/screens/login/profile.dart';
import 'package:capstone/screens/post/feedbackpage.dart';
import 'package:flutter/material.dart';
import 'package:capstone/main.dart';
import 'package:capstone/screens/post/party_board.dart';
import 'package:capstone/screens/post/free_board.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/login/login_form.dart';
import 'package:capstone/screens/post/QnA_board.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/post/notice_1st.dart';
import 'package:capstone/screens/prof/prof_profile.dart';
import 'package:capstone/screens/gScore/gscore_list_screen.dart';
import 'package:capstone/screens/gScore/gscore_admin_editor.dart';
import 'package:capstone/screens/gScore/gscore_admin_list.dart';
import 'package:capstone/screens/subject/MSmain.dart';
import 'package:capstone/screens/subject/MSmain_ASS.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);


  @override
  _MyDrawerState createState() => _MyDrawerState();
}


class _MyDrawerState extends State<MyDrawer> {
  int? _userPermission;
  bool _isNotified = false;
  String _errorMessage = '';
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _studentinfo();
    _getNotificationStatus(); // Call _getNotificationStatus() here
  }

  Future<bool> _getNotificationStatus() async {
    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      return false;
    }

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/getnotification'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _isNotified = responseData[0]['is_notified'] == 1 ? true : false;
      });
    }

    return false;
  }

  void _updateNotificationStatus() async {
    final storage = FlutterSecureStorage();
    setState(() => _isLoading = true);
    final token = await storage.read(key: 'token');
    if (token == null) {
      return;
    }

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/post/updatenotification'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _isNotified = false;
      });
    }
  }

  void logout(BuildContext context) async {
    final storage = new FlutterSecureStorage();
    await storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  String? _accountName;
  String? _accountEmail;
  String? _accountPermission;

  void sendFeedback(String feedbackText) async {
    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보를 받아올 수 없습니다. (로그인 만료)'), backgroundColor: Colors.red,),
        );
      });
      return;
    }

    final Map<String, dynamic> postData = {
      'board_id': 90, // 게시판 ID를 적절히 설정하세요.
      'post_title': feedbackText,
      'post_content': '',
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
      Navigator.pop(context, true);
    } else {
      // Failure
      final responseData = jsonDecode(response.body);
      setState(() {
        _isLoading = false;
        _errorMessage = responseData['message'];
      });
    }
  }


  void _studentinfo() async {
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '토큰이 없습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보를 받아올 수 없습니다. (로그인 만료)'), backgroundColor: Colors.red,),
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
        _accountName = responseData[0]['student_id'].toString();
        _accountEmail = responseData[0]['name'];
        _userPermission = responseData[0]['permission']; // 추가
        _accountPermission = responseData[0]['permission'].toString();
      });
      _getNotificationStatus();
    } else {
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
    if (_accountName == null) {
      return Center(child: CircularProgressIndicator());
    }
    var a = 0;
    final String fileName = _accountName! + '.png';
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    a++;
                    print(a);
                    if(a == 1){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('어라?..'),
                            content: Text('계속 누르면 뭔가 있을거 같지 않아?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('닫기'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (a == 5) { // a 값이 1인 경우에만 AlertDialog 반환
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('거의 다 와가'),
                            content: Text('더 눌러봐'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('닫기'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (a == 21) { // a 값이 1인 경우에만 AlertDialog 반환
                      a = 0;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('주모'),
                            content: Text('서버 좀 켜줘'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('닫기'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Color(0xffC1D3FF),
                    ),
                    currentAccountPicture: ClipOval(
                      child: Image.network(
                        'http://203.247.42.144:443/user/loding?image=$fileName',
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            return CircularProgressIndicator();
                          }
                        },
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          return Image.asset(
                            'assets/profile.png',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    accountName: Text(_accountName ?? ''),
                    accountEmail: Text(_accountEmail ?? ''),
                  ),

                ),
                ListTile(
                  leading: Icon(Icons.home, color: Colors.grey[800]),
                  title: Text('홈'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                ),
                ListTile(
                    leading: Icon(Icons.person, color: Colors.grey[800]),
                    title: Text('프로필'),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Profile()),
                      );
                    }
                ),
                ExpansionTile(
                  title: Text('게시판'),
                  trailing: _isNotified ? Icon(Icons.fiber_new_outlined, color: Colors.red) : null,
                  leading: Icon(Icons.article, color: Colors.grey[800]),
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.announcement, color: Colors.grey[800]),
                      title: Text('공지사항'),
                      trailing: _isNotified ? Icon(Icons.fiber_new_outlined, color: Colors.red) : null,
                      onTap: () {
                        _updateNotificationStatus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NoticeTalkScreen_1(boardId: 1)),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.chat, color: Colors.grey[800]),
                      title: Text('구인구직 게시판'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PartyBoardScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.article, color: Colors.grey[800]),
                      title: Text('자유게시판'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FreeBoardScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.article, color: Colors.grey[800]),
                      title: Text('Q&A게시판'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => QnABoardScreen()),
                        );
                      },
                    ),
                  ],
                ),
                //이수현황 - 나의 이수현황, 이수과목선택
                ExpansionTile(
                  title: Text('이수현황'),
                  leading: Icon(
                      Icons.ballot_rounded, color: Colors.grey[800]),
                  children: <Widget>[
                    ListTile(
                        leading: Icon(
                            Icons.add_reaction_outlined, color: Colors.grey[800]),
                        title: Text('나의 이수현황'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                CompletionStatusPage()),
                          );
                        }
                    ),

                    ListTile(
                      title: Text('이수과목 선택'),
                      leading: Icon(
                          Icons.add_task_rounded,
                          color: Colors.grey[800]
                      ),
                      onTap: () {

                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                CompletedSubjectSelectPage()),
                          );
                        }
                    ),
                    ListTile(
                        leading: Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.grey[800]),
                        title: Text('졸업 가이드'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                GraduationGuidePage()),
                          );
                        }
                    ),
                  ],),

                ListTile(
                    leading: Icon(Icons.school, color: Colors.grey[800]),
                    title: Text('나의 졸업인증제'),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyScorePage()),
                      );
                    }
                ),

                ListTile(
                  leading: Icon(Icons.menu_book_rounded, color: Colors.grey[800]),
                  title: Text('전공과목 정보'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MSmain()),
                    );
                  },
                ),

                _accountPermission == "2" || _accountPermission == "3" ?
                ExpansionTile(
                    title: Text('관리자 페이지'),
                    leading: Icon(Icons.subdirectory_arrow_left, color: Colors.grey[800]),
                    children: <Widget>[
                      ListTile(
                          leading: Icon(Icons.person_add, color: Colors.grey[800]),
                          title: Text('교수 계정 생성'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            );
                          }
                      ),
                      ListTile(
                        leading: Icon(Icons.person, color: Colors.grey[800]),
                        title: Text('교수 정보 관리'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfProfile()),
                          );
                        },
                      ),
                      ListTile(
                          leading: Icon(Icons.note_alt, color: Colors.grey[800]),
                          title: Text('과목 정보 수정'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MSmainASS()),
                            );
                          }
                      ),
                      ExpansionTile(
                        title: Text('졸업인증제 관리'),
                        leading: Icon(
                            Icons.school, color: Colors.grey[800]),
                        children: <Widget>[
                      ListTile(
                          leading: Icon(Icons.article, color: Colors.grey[800]),
                          title: Text('신청 게시글 목록'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GScoreForm()),
                            );
                          }
                      ),
                      ListTile(
                          leading: Icon(Icons.edit_note, color: Colors.grey[800]),
                          title: Text('졸업인증 항목 관리'),
                          onTap: (){
                            if (_accountPermission == "3") {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('권한 없음'),
                                    content: Text('해당 기능은 관리자만 이용할 수 있습니다.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // 경고창 닫기
                                        },
                                        child: Text('확인'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            else{
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GScoreEditor()),
                            );
                            }
                          }
                      ),
                      ListTile(
                          leading: Icon(Icons.playlist_add_check, color: Colors.grey[800]),
                          title: Text('관리자 단체 승인'),
                          onTap: (){
                            if (_accountPermission == "3") {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('권한 없음'),
                                    content: Text('해당 기능은 관리자만 이용할 수 있습니다.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // 경고창 닫기
                                        },
                                        child: Text('확인'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AdminGScoreForm()),
                              );
                            }
                          }
                      ),
                      ListTile(
                        leading: Icon(Icons.search, color: Colors.grey[800]),
                        title: Text('학생 점수 열람'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AdminCheckPage()),
                          );
                        },
                      ),
                      ],),
                      ListTile(
                          leading: Icon(Icons.dynamic_feed, color: Colors.grey[800]),
                          title: Text('피드백 및 신고글'),
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FeedBackScreen()),
                            );
                          }
                      ),
                    ])
                    : Container(),
              ],
            ),

          ),
          ListTile(
            leading: Icon(Icons.feedback, color: Colors.grey[800]),
            title: Text('피드백'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String feedbackText = ''; // 피드백 텍스트를 저장할 변수

                  return AlertDialog(
                    title: Text('피드백 보내기'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: '피드백 작성',
                          ),
                          textInputAction: TextInputAction.newline, // 엔터를 눌렀을 때 다음 줄로 이동
                          maxLines: null,
                          onChanged: (value) {
                            feedbackText = value; // 텍스트 필드 값이 변경될 때마다 변수에 저장
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text('취소'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('보내기'),
                        onPressed: () {
                          // 피드백 보내기 로직을 여기에 구현하세요.
                          // feedbackText 변수에 텍스트 필드의 값이 저장되어 있습니다.
                          // 예를 들어, sendFeedback 함수를 호출하여 피드백을 처리한다면:
                          sendFeedback(feedbackText);

                          Navigator.of(context).pop(); // 팝업 창 닫기

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '피드백이 성공적으로 전송되었습니다.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                              backgroundColor: Colors.green, // 배경색 설정
                              duration: Duration(seconds: 3), // 표시 시간 설정

                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.grey[800]),
            title: Text('로그아웃'),
            onTap: () {
              logout(context);
            },
          ),
        ],
      ),
    );
  }
}
