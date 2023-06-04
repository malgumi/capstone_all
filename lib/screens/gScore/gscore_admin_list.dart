import 'package:flutter/material.dart';
import 'package:capstone/screens/gScore/gscore_modify_screen.dart';
import 'package:capstone/screens/gScore/gscore_admin_regist_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//신청글 목록 창
final client = HttpClient();



void main() {
  runApp(MaterialApp(
    title: '단체 승인글 목록',
    home: AdminGScoreForm(),
  ));
}


class AdminGScoreForm extends StatefulWidget {
  @override
  _AdminGScoreForm createState() => _AdminGScoreForm();
}

class _AdminGScoreForm extends State<AdminGScoreForm> {

  String postFilter = '전체';
  String searchText = '';
  int userId = 0;
  int userPermission = 0;

  late Future<dynamic> _posts =  Future(() => null);

  List<dynamic> allPosts = [];
  List<dynamic> filteredPosts = [];



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

  Future<void> _fetchMyPosts() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if(token == null){
      return ;
    }
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/assposts'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _posts = Future.value(data);
      allPosts = await _posts;
      filteredPosts = allPosts;

      setState(() {
        _posts;
        allPosts;
        filteredPosts;
      });
    } else if(response.statusCode == 401){
      throw Exception('로그인 정보 만료됨');
    }
    else if(response.statusCode == 500){
      throw Exception('서버 에러');
    }
  }


  void _filterStatus(String value){
    if(value == '관리자승인'){
      filteredPosts = allPosts.where((post) => post['gspost_category'] == '관리자승인').toList();
    }

    setState(() {
      filteredPosts;
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
              Container(width: MediaQuery.of(context).size.width * 0.1,
                alignment: Alignment.center,
                child: Text(post['gspost_id'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.2,
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
              Container(width: MediaQuery.of(context).size.width * 0.3,
                alignment: Alignment.center,
                child: Text(
                  post['gspost_item'].toString(),
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(width: MediaQuery.of(context).size.width * 0.18,
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
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    _filterStatus('관리자승인');
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '  단체 승인글 목록  ',
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
          Column(
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GScoreAdminRegist()),
                      );
                    },
                    child: Text(
                      '신청',
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffC1D3FF),
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    ),
                  ),
                  SizedBox(width: 15,)
                ],
              ),
              SizedBox(height: 10),
              Container(
                width: MediaQuery.of(context).size.width * 0.97,
                height: MediaQuery.of(context).size.height * 0.8,
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
                      padding: EdgeInsets.all(16.0),
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
                          SizedBox(width: 10),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.12,
                            alignment: Alignment.center,
                            child: Text(
                              "추가일",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            alignment: Alignment.center,
                            child: Text(
                              "활동명",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.07,
                            alignment: Alignment.center,
                            child: Text(
                              "점수",
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
                          future: Future.value(filteredPosts),
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
                                child: Text('${snapshot.error}',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),),
                              );
                            }else {
                              return Center(child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          )
        ]

        )
    );

  }
}
