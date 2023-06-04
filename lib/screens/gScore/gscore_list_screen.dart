import 'package:flutter/material.dart';
import 'package:capstone/screens/gScore/gscore_modify_screen.dart';
import 'package:capstone/screens/gScore/gscore_regist_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';


//신청글 목록 창
final client = HttpClient();



void main() {
  runApp(MaterialApp(
    title: '졸업인증제 신청 현황',
    home: GScoreForm(),
  ));
}


class GScoreForm extends StatefulWidget {
  @override
  _GScoreForm createState() => _GScoreForm();
}

class _GScoreForm extends State<GScoreForm> {

  String postFilter = '전체';
  String searchText = '';
  int userId = 0;
  int userPermission = 0;

  late Future<dynamic> _posts =  Future(() => null);

  List<dynamic> allPosts = [];
  List<dynamic> firstFilteredPosts = [];
  List<dynamic> secondFilteredPosts = [];



  @override
  void initState() {
    super.initState();
    checkUserLoginStatus();
    _fetchMyPosts();
    _getUserInfo();

  }


  void checkUserLoginStatus() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      Navigator.pop(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('알림'),
            content: Text('해당 기능은 로그인 후 이용이 가능합니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('확인'),
              ),
            ],
          );
        },
      );
    }
  }

  _launchURL() async {
    const url = 'http://ce.hannam.ac.kr/sub5/menu_1.html?pPostNo=176133&pPageNo=4&pRowCount=10&isGongjiPostList=N';
    final Uri uri = Uri.parse(url);
    print(uri);
    await launchUrl(uri);

  }

  Future<void> _fetchMyPosts() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if(token == null){
      return ;
    }
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/posts'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _posts = Future.value(data);
      allPosts = await _posts;
      firstFilteredPosts = allPosts;
      secondFilteredPosts = allPosts;

      setState(() {
        _posts;
        allPosts;
        firstFilteredPosts;
        secondFilteredPosts;
      });
    } else if(response.statusCode == 401){
      throw Exception('로그인 정보 만료됨');
    }
    else if(response.statusCode == 500){
      throw Exception('서버 에러');
    }
  }


  void _filterStatus(String value){
    if(value == '전체'){
      secondFilteredPosts = firstFilteredPosts;
    }else if(value == '승인') {
      secondFilteredPosts =
          firstFilteredPosts.where((post) => post['gspost_pass'] == '승인').toList();
    }else if (value == '미승인') {

      List<dynamic> waitingPosts = firstFilteredPosts.where((post) => post['gspost_pass'] == '대기').toList();
      List<dynamic> rejectedPosts = firstFilteredPosts.where((post) => post['gspost_pass'] == '반려').toList();
      secondFilteredPosts = [...waitingPosts, ...rejectedPosts];

    }
    setState(() {
      secondFilteredPosts;
    });
  }

  void _filterWriter(String value) async {
    allPosts = await _posts;
    firstFilteredPosts = allPosts
        .where((post) => post['gsuser_id'].toString().contains(value))
        .toList();
    secondFilteredPosts = firstFilteredPosts;
    postFilter = '전체';


    setState(() {
      firstFilteredPosts;
      secondFilteredPosts;
      postFilter;
    });
  }


  Future<void> _getUserInfo() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      return;
    }
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      userId = user['student_id'];
      userPermission = user['permission'];

      setState(() {
        userId;
        userPermission;
      });
    } else {
      throw Exception('예외 발생');
    }
  }





  Widget _buildPostItem(BuildContext context, dynamic post) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GScoreApcCt(post: post),
          ),
        );
        setState(() {
          //final _posts = _fetchAllPosts();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Container(
          width: 200.0,
          height: 70.0,
          padding: EdgeInsets.all(13.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
            border: Border.all(
              width: 2,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: MediaQuery.of(context).size.width * 0.08,
                alignment: Alignment.center,
                child: Text(post['gspost_id'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.17,
                alignment: Alignment.center,
                child: Text(

                  DateTime.parse(post['gspost_post_date']).toLocal().toString().substring(2, 10),
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.30,
                alignment: Alignment.center,
                child: Text(
                  post['gspost_category'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.13,
                alignment: Alignment.center,
                child: Text(
                  post['gspost_score'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(width: 18,),
              Container(width: MediaQuery.of(context).size.width * 0.1,
                alignment: Alignment.center,
                child: Text(
                  post['gspost_pass'].toString(),
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '  졸업인증제 신청/관리  ',
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
        body:ListView(children: [
          Container(height: MediaQuery.of(context).size.height * 0.01),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.97,
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
                color: Color(0xFFF4F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Align(
                alignment: Alignment.center,
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: TextStyle(fontSize: 15.0, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(text: '1.각 항목별 점수를 확인해주세요.\n'),
                      TextSpan(
                        text: '\n',
                        style: TextStyle(fontSize: 4.0),
                      ),
                      TextSpan(
                        text: '2.승인받은 게시글은 내 졸업인증점수에 반영됩니다. \n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '\n',
                        style: TextStyle(fontSize: 4.0),
                      ),
                      TextSpan(
                        text: '3.인턴쉽, 해외연수 50일 이상의 점수는\n   첨부파일 확인후 ',
                      ),
                      TextSpan(
                        text: '조교가 수기 입력',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '합니다.\n',
                      ),
                      TextSpan(
                        text: '\n',
                        style: TextStyle(fontSize: 4.0),
                      ),
                      TextSpan(
                        text: '졸업인증 점수 내규 보러가기',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w300,
                          fontFamily: "NotoSansCJKkr",
                          fontStyle: FontStyle.normal,
                          fontSize: 15.0,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async{
                            _launchURL();
                          },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),




          Container(
              height: MediaQuery.of(context).size.height * 0.01
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(width: 10,),
              Container(
                  width: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  padding: const EdgeInsets.fromLTRB(10.0, 6.0, 4.0, 6.0),
                  child: Row(children: [
                    DropdownButton<String>(
                      value: postFilter,
                      onChanged: (String? newValue) {
                        _filterStatus(newValue ?? '');
                        setState(() {
                          postFilter = newValue ?? '' ;

                        });
                      },
                      items: <String>['전체', '승인', '미승인']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                      ),
                      underline: Container(), // 드롭다운 버튼 하단의 선 제거
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GScoreForm()),
                          );
                        },
                        icon: Icon(Icons.refresh),
                        color: Colors.grey,
                        iconSize: 22.0,
                      ),
                    ),
                  ],)
              ),
              SizedBox(width: 12,),
              Expanded(
                flex: 7,
                child: Visibility(
                  visible: userPermission == 2 || userPermission == 3,
                  child: Container(
                    margin: EdgeInsets.only(right: 8.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                      decoration: InputDecoration(
                        labelText: '학번 검색',
                        hintText: '검색',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            _filterWriter(searchText);
                          },
                          icon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if(userPermission ==1){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GScoreApc()),
                    );
                  }
                },
                child: Text(
                  '신청',
                  style: TextStyle(fontSize: 15),
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    userPermission == 1
                        ? Color(0xffC1D3FF)
                        : Color(0xffbabfcc),
                  ),
                  fixedSize: MaterialStateProperty.all<Size>(
                    Size(width * 0.08, height * 0.055),
                  ),
                ),
              ),

              Container(width: 10,),
            ],
          ),
          Container(
              height: MediaQuery.of(context).size.height * 0.01
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.97,
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.0), // 상하좌우 16.0씩 padding 적용
                  width: double.infinity,
                  height: 50,
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.13,
                        alignment: Alignment.center,
                        child: Text(
                          "No.",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(width: 10,),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        alignment: Alignment.center,
                        child: Text(
                          "신청일",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.33,
                        alignment: Alignment.center,
                        child: Text(
                          "활동종류",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        alignment: Alignment.center,
                        child: Text(
                          "점수",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.22,
                        alignment: Alignment.center,
                        child: Text(
                          "신청상태",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: FutureBuilder<dynamic>(
                      future: Future.value(secondFilteredPosts),
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
                ),
              ],
            ),
          ),

        ],
        )
    );
  }
}