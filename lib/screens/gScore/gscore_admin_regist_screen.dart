import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/gScore/gscore_admin_list.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

//신청창
void main() {
  runApp(MaterialApp(
    title: '단체 승인글 작성',
    home: GScoreAdminRegist(),
  ));
}

class GScoreAdminRegist extends StatefulWidget {
  const GScoreAdminRegist({Key? key}) : super(key: key);

  @override
  _GScoreAdminRegistState createState() => _GScoreAdminRegistState();
}

class _GScoreAdminRegistState extends State<GScoreAdminRegist> {
  void initState() {
    super.initState();
    _getuserInfo();
  }

  Future<void> _writePostAndFile() async {
    if (_activityName == null || _score == null || int.parse(_score ?? '0') < 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('알림'),
            content: Text('활동명과 점수를 확인해주세요.'),
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
      return; // 함수 종료
    }

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('실패: 로그인 정보 없음')));
      });
      return;
    }

    List<int> stuId = [];

    userInfosave.keys.forEach((key) {
      stuId.add(key);
    });

    print(stuId);
    final Map<String, dynamic> postData = {
      'gspost_student': stuId,
      'gspost_category': _activityType,
      'gspost_item': _activityNamecontroller.text,
      'gspost_score': _score,
      'gspost_content': _contentController.text,
      'gspost_pass': '승인',
      'gspost_reason': '',
      'gspost_file': '0',
    };
    print(postData);
    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/gScore/allwrite'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode(postData),
    );

    print(response.statusCode);

    if (response.statusCode == 201) {
      postUploadCheck = 1;
    } else {
      print(response.statusCode);
      print('에러');
    }
    final Map<String, dynamic> postData2 = {
      'gspost_student': stuId,
      'gspost_category': _activityType,
      'gspost_item': _activityNamecontroller.text,
      'gspost_score': _score,
      'gspost_content': _contentController.text,
      'gspost_pass': '대기',
      'gspost_reason': '',
      'gspost_file': '0',
    };
    final assWriteResponse = await http.post(
      Uri.parse('http://203.247.42.144:443/gScore/asswrite'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode(postData2),
    );

    print(assWriteResponse.statusCode);

    if (assWriteResponse.statusCode == 201) {
      // Success
    } else {
      print(assWriteResponse.statusCode);
      print('에러');
    }
  }

  Future<void> _getuserInfo() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/allUser'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      final userInfoTemp = jsonDecode(response.body);
      for (var item in userInfoTemp) {
        String userName = item['name'];
        int userId = item['student_id'];
        int userGrade = item['grade'];
        userInfo[userId] = userInfo[userId] = {userName: userGrade};
      }
      print(userInfo);
    } else {
      throw Exception('예외 발생');
    }
  }
  //학생정보 리스트
  Map<int, Map<String, int>> userInfo = {};

  //선택한 학생 정보 저장
  Map<int, String> userInfosave = {};
  TextEditingController _userid = TextEditingController();
  int? _searchId;

  //활동종류
  String _activityType = "관리자승인";

  //활동명
  TextEditingController _activityNamecontroller = TextEditingController();
  String? _activityName;

  //점수
  TextEditingController _scoreController = TextEditingController();
  String? _score;

  void testPrint() {
    print(userInfosave);
    print(_activityType);
    print(_activityName);
    print(_score);
    print(userInfosave.keys);
  }

  bool isEditable = false;

  //비고란
  TextEditingController _contentController = TextEditingController();

  //작성된 게시글 번호
  int postId = 0;

  //게시글이 정상적으로 업로드 되었는지 체크
  int postUploadCheck = 0;

  final _formKey = GlobalKey<FormState>();

  void addUserInfo(int grade) {
    for (var entry in userInfo.entries) {
      var innerMap = entry.value;
      for (var innerEntry in innerMap.entries) {
        if (innerEntry.value == grade && !userInfosave.containsKey(entry.key)) {
          setState(() {
            userInfosave[entry.key] = innerEntry.key;
          });
          break;
        }
      }
    }
  }

  void addSearchUserInfo() {
    if (_searchId != null && !userInfosave.containsKey(_userid.text)) {
      int userid = int.parse(_userid.text);
      setState(() {
        var userInfo2 = userInfo[userid];
        if (userInfo2 != null) {
          var value = userInfo2.keys.toString();
          userInfosave[userid] = value.substring(1, value.length - 1);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '단체 승인게시글 작성',
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
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: true,
                    initialValue: _activityType,
                    decoration: InputDecoration(
                      labelText: '활동종류',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _activityNamecontroller,
                    decoration: InputDecoration(
                      labelText: '활동명',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _activityName = value;
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _scoreController,
                          decoration: const InputDecoration(
                            labelText: '점수',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _score = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            TextFormField(
                              controller: _userid,
                              decoration: const InputDecoration(
                                labelText: '학생 추가',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _searchId = int.tryParse(value);
                                });
                              },
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Material(
                                borderRadius: BorderRadius.circular(24.0),
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    addSearchUserInfo();
                                    testPrint();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(Icons.add),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 0, // 최소 수직 크기
                        maxHeight: 300, // 최대 수직 크기
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userInfo.length,
                        itemBuilder: (context, index) {
                          int key = userInfo.keys.elementAt(index);
                          String? name = userInfo[key]?.keys.isNotEmpty == true ? userInfo[key]!.keys.first : null;
                          int? grade = userInfo[key]![name];
                          if (_searchId != null &&
                              key.toString().startsWith(_searchId.toString())) {
                            return ListTile(
                              title: Text('$name($key) $grade학년'),
                              onTap: () {
                                setState(() {
                                  _userid.text = key.toString();
                                });
                              },
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    )),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // 좌우 스크롤 가능하도록 설정
                    child: Row(
                      children: [
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            addUserInfo(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffC1D3FF),
                          ),
                          child: Text('1학년'),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            addUserInfo(2);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffC1D3FF),
                          ),
                          child: Text('2학년'),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            addUserInfo(3);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffC1D3FF),
                          ),
                          child: Text('3학년'),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            addUserInfo(4);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffC1D3FF),
                          ),
                          child: Text('4학년'),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              userInfosave.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffC1D3FF),
                          ),
                          child: Text('비우기'),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8.0,
                          children: userInfosave.entries.map((entry) {
                            int key = entry.key;
                            String value = entry.value;
                            int? grade = userInfo[key]![value];
                            return Chip(
                              label: Text('$value($key) $grade학년'),
                              onDeleted: () {
                                setState(() {
                                  userInfosave.remove(key);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: '비고',
                      border: OutlineInputBorder(),
                    ),
                    controller: _contentController,
                  ),
                ),
                // 신청 상태에 대한 드롭다운형식의 콤보박스
                const SizedBox(height: 8),
                // 저장 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    elevation: 5.0, //그림자효과
                    borderRadius: BorderRadius.circular(30.0), //둥근효과
                    color: (_activityName != null && _score != null && _activityName != "" && _score != "" && userInfosave.isNotEmpty)
                        ? const Color(0xffC1D3FF)
                        : const Color(0xff808080),
                    child: MaterialButton(
                      onPressed: () async {
                        if(_activityName != null && _score != null && _activityName != "" && _score != "" && userInfosave.isNotEmpty){
                          testPrint();
                          await _writePostAndFile();
                          if (postUploadCheck == 1) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) => AdminGScoreForm()))
                                .then((value) {
                              setState(() {});
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('게시글 작성 실패: 서버 오류')));
                          }
                        }
                      },
                      child: const Text(
                        "저장",
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
