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

  String? _selectedYear;
  String? _selectedMajor;

  @override
  void initState() {
    super.initState();

    // Frame이 그려진 후에 `loadSubjects`를 호출합니다.
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      Provider.of<CompletionProvider>(context, listen: false).loadSubjects();
    });
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
              height: 140,
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
                      fontSize: 30.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                  const Text(
                    'Graduation Guide',
                    style: TextStyle(
                      color: Color(0xff858585),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            //입학년도와 전공(이수)유형
            Container(
              alignment: Alignment.centerLeft,
              height: 80,
              width: double.infinity,
              padding: EdgeInsets.only(
                left: 30.0,
                top: 20.0,
                right: 10.0,
                bottom: 20.0,
              ),
              decoration: BoxDecoration(
                color: Color(0xf6dce1ff),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      alignment: Alignment.center,
                      padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        '입학년도',
                        style: TextStyle(
                            color: Color(0xff5c6bb9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      )),
                  SizedBox(width: 2,),
                  Consumer<CompletionProvider>(
                    builder: (context, completionProvider, child) {
                      return FutureBuilder<int>(
                        future: completionProvider.getAdmissionYear(),
                        // 입학년도 보여줌
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
                                '${snapshot.data}년도',
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
                  SizedBox(width: 10,),
                  Container(
                      alignment: Alignment.center,
                      padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        '전공(이수)유형',
                        style: TextStyle(
                            color: Color(0xff5c6bb9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      )),
                  SizedBox(width: 2,),
                  FutureBuilder(
                    future: Future.wait([
                      completionProvider.getSelectedMajor(),
                      completionProvider.getCreditToGraduate()
                    ]),
                    builder:
                        (BuildContext context, AsyncSnapshot<List> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final selectedMajor = snapshot.data?[0] as String?;
                        final creditToGraduate = snapshot.data?[1] as int?;

                        return Text('${selectedMajor ?? '주전공'}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600));
                      }
                    },
                  )
                ],
              ),
            ),
            SizedBox(height: 40,),

            //졸업기준학점과 부족한 전공학점
            Container(
              width: double.infinity,
              height: 140,
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    width: 1.5,
                    color: Color(0xff000000),
                    style: BorderStyle.solid),
                boxShadow: [
                  BoxShadow(
                      color: Color(0xff858585),
                      offset: Offset(0, 3),
                      blurRadius: 3.0,
                      spreadRadius: 0.0)
                ],
                color: Color(0xffffcfcfc),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder(
                    future: Future.wait([
                      completionProvider.getSelectedMajor(),
                      completionProvider.getCreditToGraduate()
                    ]),
                    builder:
                        (BuildContext context, AsyncSnapshot<List> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final selectedMajor = snapshot.data?[0] as String?;
                        final creditToGraduate = snapshot.data?[1] as int?;

                        return Row(
                          children: [
                            Text(
                                '졸업기준학점 : ${creditToGraduate != null ? creditToGraduate.toString() : '66'}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(' 학점',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600))
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: 15,),
                  Row(
                    children: [
                      const Text(
                        '부족한 전공학점 : ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
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
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              );
                            }
                          }),
                      Text(
                        ' 학점',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.0,),

            //필수이수과목
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      width: 1.5,
                      color: Color(0xff000000),
                      style: BorderStyle.solid),
                  color: Color(0xffffcfcfc),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0xff858585),
                        offset: Offset(0, 3),
                        blurRadius: 3.0,
                        spreadRadius: 0.0)
                  ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //필수이수과목 타이틀
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '필수이수과목',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22.0,
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
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.0,),
                  Text(
                    '  ※ 전공기초과목이 필수이수과목입니다.',
                    style: TextStyle(
                      color:  Color(0xff686868),
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 30,),

                  //입학년도,전공유형별 필수이수과목 리스트
                  Consumer<CompletionProvider>(
                    builder: (context, completionProvider, child) {
                      List<String> completedCompulsorySubjects = completionProvider
                          .completedCompulsory
                          .map((subject) => subject.subjectName)
                          .toList();

                      return FutureBuilder<Set<String>>(
                        future: completionProvider.getRequiredCourses(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('오류가 발생했습니다. ${snapshot.error}');
                          } else {
                            Set<String> requiredCourses = snapshot.data ?? {};

                            // 모든 필수 이수 과목이 이수한 과목에 포함되어 있는지 확인합니다.
                            bool hasCompletedAllRequired = requiredCourses
                                .every((course) => completedCompulsorySubjects.contains(course));

                            if (hasCompletedAllRequired) {
                              return Center(
                                child: Text(
                                  '필수이수과목을 모두 이수했습니다!',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            } else {
                              // 필수 이수 과목 중 이수하지 않은 과목들을 찾습니다.
                              Set<String> missingCourses = requiredCourses.difference(
                                  completedCompulsorySubjects.toSet());

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      '아래의 과목들을 이수해야 합니다',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 15,),
                                  ...missingCourses
                                      .map((course) => Container(
                                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                                    margin: EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: Color(0xffff5f5f5),
                                      borderRadius: BorderRadius.circular(15),
                                      /*border: Border.all(
                                          width: 1.5,
                                          color: Color(0xff000000),
                                          style: BorderStyle.solid),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Color(0xff858585),
                                            offset: Offset(0, 1),
                                            blurRadius: 1.0,
                                            spreadRadius: 0.0)
                                      ],*/
                                    ),
                                    child: Text(
                                      course,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  SizedBox(height: 50,),

                                  //이수했다면 이수과목에 추가해주세요!, 이수과목 추가 버튼
                                  Container(
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Text(
                                          '이수했다면 이수과목에 추가해주세요!',
                                          style: TextStyle(
                                            color: Color(0xff858585),
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 15,),
                                        //이수과목 추가 버튼
                                        Container(
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              height: 35,
                                              width: 100,
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
                                                child: const Text('이수과목 추가'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xff341F87),
                                                  padding: EdgeInsets.fromLTRB(8, 5, 8, 5),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6.0),
                                                  ),
                                                  minimumSize: Size(90, 30),
                                                  textStyle: TextStyle(
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20,),
                ],
              ),
            ),
            SizedBox(height: 40),

            //캡스톤디자인 이수 여부
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(left: 30.0, right: 30.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    width: 1.5,
                    color: Color(0xff000000),
                    style: BorderStyle.solid),
                boxShadow: [
                  BoxShadow(
                      color: Color(0xff858585),
                      offset: Offset(0, 3),
                      blurRadius: 3.0,
                      spreadRadius: 0.0)
                ],
                color: Color(0xffffcfcfc),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //캡스톤디자인 타이틀
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '캡스톤디자인',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          height: 5.0,
                        ),
                        const Text(
                          'Capstone Design',
                          style: TextStyle(
                            color: Color(0xff858585),
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),

                  //캡스톤 이수여부 판단
                  Consumer<CompletionProvider>(
                    builder: (context, completionProvider, child) {
                      bool hasCompletedCapstone = completionProvider.completedElective
                          .any((subject) => subject.subjectName == '캡스톤디자인');

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              hasCompletedCapstone ? '캡스톤 디자인을 이수했습니다!' : '캡스톤 디자인을 이수해야 합니다',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 50,),
                          if (!hasCompletedCapstone)
                            Container(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(
                                    '이수했다면 이수과목에 추가해주세요!',
                                    style: TextStyle(
                                      color: Color(0xff858585),
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 15,),
                                  //이수과목 추가 버튼
                                  Container(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        height: 35,
                                        width: 100,
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
                                          child: const Text('이수과목 추가'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xff341F87),
                                            padding: EdgeInsets.fromLTRB(8, 5, 8, 5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            minimumSize: Size(90, 30),
                                            textStyle: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20,),
                ],
              ),
            ),
            SizedBox(height: 80,),

            //나의 이수현황 보기 버튼
            Container(
              alignment: Alignment.center,
              height: 50,
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return ChangeNotifierProvider<CompletionProvider>.value(
                        value: Provider.of<CompletionProvider>(context,
                            listen: false),
                        child: CompletionStatusPage(),
                      );
                    }),
                  );
                },
                child: const Text('나의 이수현황 보기',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffffffff),
                  padding: EdgeInsets.fromLTRB(8, 5, 8, 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  side: BorderSide(color: Color(0xff341F87), width: 2.0),
                  minimumSize: Size(220, 60),
                ),
              ),
            ),
            SizedBox(height: 150),

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
