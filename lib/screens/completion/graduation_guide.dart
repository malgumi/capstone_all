import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/completion_provider.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';
import 'package:capstone/screens/completion/subject_model.dart';
import 'package:capstone/screens/subject/CS_Tab.dart';
import 'package:capstone/screens/subject/ES_Tab.dart';

//졸업가이드

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CompletionProvider(),
      child: MaterialApp(
        title: 'capstone',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: GraduationGuidePage(),
      ),
    );
  }
}

//이수과목 모델
class CompletedSubjects {
  final int studentId;
  final int subjectId;
  final int proId;

  const CompletedSubjects({
    required this.studentId,
    required this.subjectId,
    required this.proId,
  });

  factory CompletedSubjects.fromJson(Map<String, dynamic> json) {
    return CompletedSubjects(
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      proId: json['pro_id'],
    );
  }
}

//나의이수현황 페이지
class GraduationGuidePage extends StatefulWidget {
  @override
  State<GraduationGuidePage> createState() => _GraduationGuidePageState();
}

class _GraduationGuidePageState extends State<GraduationGuidePage> {
  final storage = FlutterSecureStorage();
  late Future<List<Subject>> futureCompletedSubjects;

  @override
  void initState() {
    super.initState();

    // Frame이 그려진 후에 `loadSubjects`를 호출합니다.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Provider.of<CompletionProvider>(context, listen: false).loadSubjects();
    });
  }

  //이수과목 정보 불러오기
  Future<List<Subject>> fetchCompletedSubjects() async {
    print('Fetching completed subjects...');

    final token = await storage.read(key: 'token'); // Storage에서 토큰 읽기
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/user/required'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token, // 헤더에 토큰 추가
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final List<Subject> subjects =
          data.map((item) => Subject.fromJson(item)).toList();

      print('Completed subjects retrieved: $subjects');

      return subjects;
    } else {
      throw Exception('Failed to load saved subjects');
    }
  }

  //빌드
  @override
  Widget build(BuildContext context) {
    CompletionProvider completionProvider =
        Provider.of<CompletionProvider>(context);
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '졸업 가이드',
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
      drawer: MyDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //졸업가이드 title
            Container(
              alignment: Alignment.centerLeft,
              height: 120,
              padding: EdgeInsets.only(
                left: 25.0,
                top: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              decoration: BoxDecoration(
                color: Color(0xffffffff),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '졸업 가이드',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  const Text(
                    'Graduation Guide',
                    style: TextStyle(
                      color: Color(0xff858585),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            //부족한 전공학점
            Container(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    padding: EdgeInsets.fromLTRB(22, 16, 16, 16),
                    margin: EdgeInsets.only(left: 30.0, right: 30.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xffF5F5F5),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xff858585),
                              offset: Offset(0, 5),
                              blurRadius: 5.0,
                              spreadRadius: 0.0)
                        ]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          ' 앞으로 ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        FutureBuilder<int>(
                            future: Provider.of<CompletionProvider>(context,
                                    listen: false)
                                .getLackingCredits(),
                            builder: (BuildContext context,
                                AsyncSnapshot<int> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('오류가 발생했습니다. ${snapshot.error}');
                              } else {
                                int? lackingCredits = snapshot.data;
                                return Text(
                                  ' ${lackingCredits}',
                                  style: TextStyle(
                                    color: Color(0xffE00909),
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              }
                            }),
                        Text(
                          ' 학점을 더 이수해야 합니다 :)',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40.0,
            ),

            //필수이수과목 title & 이수과목 편집 버튼
            Container(
              height: 80,
              padding: EdgeInsets.fromLTRB(30, 16, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                  color: Color(0xff858585),
                  width: 0.8,
                )),
                color: Color(0xffffffff),
              ),
              child: Row(
                children: [
                  //필수이수과목 title
                  Row(
                    //왼쪽 정렬
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '필수이수과목',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            const Text(
                              'Must be Completed',
                              style: TextStyle(
                                color: Color(0xff858585),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      )
                    ],
                  ),
                  //이수과목 편집 버튼
                  Expanded(
                    child: Align(
                      //오른쪽 끝 정렬
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 40,
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) {
                                return ChangeNotifierProvider<
                                    CompletionProvider>.value(
                                  value: Provider.of<CompletionProvider>(
                                      context,
                                      listen: false),
                                  child: CompletedSubjectSelectPage(),
                                );
                              }),
                            );
                          },
                          child: const Text('이수과목 편집'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff341F87),
                            padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            minimumSize: Size(100, 35),
                            textStyle: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.0),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    width: 1.2,
                    color: Color(0xff000000),
                    style: BorderStyle.solid),
                color: Color(0xffffcfcfc),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<CompletionProvider>(
                        builder: (context, completionProvider, child) {
                          return FutureBuilder<int>(
                            future: completionProvider.getAdmissionYear(),
                            // 입학년도를 가져오는 메서드
                            builder: (BuildContext context,
                                AsyncSnapshot<int> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(); // 데이터를 기다리는 동안 로딩 인디케이터를 표시
                              } else {
                                if (snapshot.hasError)
                                  return Text('Error: ${snapshot.error}');
                                else
                                  return Text(
                                    '${snapshot.data}학년도 입학생',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ); // 데이터를 가져왔으면 Text 위젯을 사용하여 표시
                              }
                            },
                          );
                        },
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      Text(
                        '※ 전공기초과목이 필수이수과목입니다.',
                        style: TextStyle(
                          color: Color(0xff858585),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Consumer<CompletionProvider>(
                        builder: (context, completionProvider, child) {
                          return FutureBuilder<int>(
                            future: completionProvider.getAdmissionYear(),
                            // 입학년도를 가져오는 메서드
                            builder: (BuildContext context,
                                AsyncSnapshot<int> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(); // 데이터를 기다리는 동안 로딩 인디케이터를 표시
                              } else {
                                if (snapshot.hasError)
                                  return Text('Error: ${snapshot.error}');
                                else {
                                  int year = snapshot.data ?? 0;
                                  if (year <= 2022) {
                                    // 입학년도가 2022년 이하인 경우
                                    return AdmissionBefore23Widget();
                                  } else {
                                    // 입학년도가 2023년 이상인 경우
                                    return AdmissionAfter23Widget();
                                  }
                                }
                              }
                            },
                          );
                        },
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CompletionStatusPage()),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_rounded,color: Color(0xff341F87),),
                              SizedBox(width: 5,),
                              Text(
                                '모두 이수했는지 확인하세요!',
                                style: TextStyle(
                                  color: Color(0xff341F87),
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20,),


            SizedBox(height: 80.0),
          ],
        ),
      ),
    );
  }
}

class AdmissionBefore23Widget extends StatelessWidget {
  const AdmissionBefore23Widget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로그래밍 실습',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '파이썬 프로그래밍',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '이산구조',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '공학과 경영',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '확률 및 통계',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AdmissionAfter23Widget extends StatelessWidget {
  const AdmissionAfter23Widget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로그래밍 실습',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '파이썬 프로그래밍',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '이산구조',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '컴퓨터개론',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '확률 및 통계',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
