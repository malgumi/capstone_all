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

//나의 이수현황

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CompletionProvider(),
      child: MaterialApp(
        title: '나의 이수현황',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CompletionStatusPage(),
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

// JWT 토큰에서 학생 ID를 가져오는 메서드
Future<String> getStudentIdFromToken() async {
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');

  if (token == null) {
    throw Exception('Token is not found');
  }

  final jwtToken = JwtDecoder.decode(token);

  return jwtToken['student_id'];
}

//나의이수현황 페이지
class CompletionStatusPage extends StatefulWidget {
  @override
  State<CompletionStatusPage> createState() => _CompletionStatusPageState();
}

class _CompletionStatusPageState extends State<CompletionStatusPage> {
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

/*
  //입학년도 가져오기
  Future<int> getAdmissionYear() async {
    String studentId = await getStudentIdFromToken();
    String yearStr = studentId.substring(2, 4);
    int year = int.parse(yearStr);

    // 학번이 2000년 이후의 경우 대비
    if(year < 30) year += 2000;
    else year += 1900;

    return year;
  }

  // 학번을 나타내는 위젯
  Widget buildStudentIdWidget(BuildContext context) {
    return FutureBuilder<int>(
        future: getAdmissionYear(),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('오류가 발생했습니다. ${snapshot.error}');
          } else {
            int? admissionYear = snapshot.data;
            return Text(
              '${admissionYear}학번 | ',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
              ),
            );
          }
        }
    );
  }


*/

  //빌드
  @override
  Widget build(BuildContext context) {
    CompletionProvider completionProvider =
        Provider.of<CompletionProvider>(context);
    return Scaffold(
      backgroundColor: Color(0xffffffff),
      appBar: AppBar(
        title: const Text(
          '이수과목',
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
            //나의 이수현황 title
            Container(
              alignment: Alignment.centerLeft,
              height: 120,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xffffffff),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '나의 이수현황',
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
                    'completion status',
                    style: TextStyle(
                      color: Color(0xff858585),
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            //전공학점
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
                          '총 전공학점 :  ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        //총전공학점
                        Consumer<CompletionProvider>(
                          builder: (context, completionProvider, child) {
                            return Text(
                              '${completionProvider.totalElectiveCredits}',
                              style: TextStyle(
                                color: Color(0xff2D0BB7),
                                fontSize: 18.0,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          },
                        ),
                        Text(
                          ' /66학점',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
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

            //전공 이수과목 title & 이수과목 편집 버튼
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
                  //전공 이수과목 title
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
                              '전공 이수과목',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            const Text(
                              'completed subject',
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

            //이수한 전공선택과목 과목명
            Container(
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    width: 1.5,
                    color: Color(0xff858585),
                    style: BorderStyle.solid),
                color: Color(0xffffffff),
              ),

              //이수한 전공선택과목 과목명
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //전공선택과목 글씨를 클릭하면 전공선택과목 검색창으로 이동
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EStab()),
                          );
                        },
                        child: const Text(
                          '전공선택과목',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 8.0,
                      ),
                      Text(
                        '${completionProvider.completedElective.length}과목 | ${completionProvider.totalElectiveCredits}학점',
                        style: TextStyle(
                          color: Color(0xff858585),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  // Consumer를 사용해서 이수 과목 목록을 가져옵니다.
                  Consumer<CompletionProvider>(
                    builder: (context, completionProvider, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: completionProvider.completedElective
                            .map((subject) => Text(subject.subjectName))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),

            //이수한 전공기초과목 과목명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    width: 1.5,
                    color: Color(0xff858585),
                    style: BorderStyle.solid),
                color: Color(0xffffffff),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CStab()),
                              );
                            },
                            child: const Text(
                              '전공기초과목',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 8.0,
                          ),
                          Text(
                            '${completionProvider.completedCompulsory.length}과목 | ${completionProvider.totalCompulsoryCredits}학점',
                            style: TextStyle(
                              color: Color(0xff858585),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      Text(
                        '※ 전공기초과목은 필수이수과목이고 전공기초학점은 교양학점으로 인정됨.',
                        style: TextStyle(
                          color: Color(0xff858585),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15.0,
                  ),
                  Consumer<CompletionProvider>(
                    builder: (context, completionProvider, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: completionProvider.completedCompulsory
                            .map((subject) => Text(subject.subjectName))
                            .toList(),
                      );
                    },
                  )
                ],
              ),
            ),
            SizedBox(height: 50.0),
          ],
        ),
      ),
    );
  }
}
