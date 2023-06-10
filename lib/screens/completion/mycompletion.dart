import 'package:capstone/screens/completion/graduation_guide.dart';
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
import '../subject/MSmain.dart';

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


//나의이수현황 페이지
class CompletionStatusPage extends StatefulWidget {
  @override
  State<CompletionStatusPage> createState() => _CompletionStatusPageState();
}

class _CompletionStatusPageState extends State<CompletionStatusPage> {
  final storage = FlutterSecureStorage();
  late Future<List<Subject>> futureCompletedSubjects;
  bool _isLoading = true; //로딩 상태를 관리하는 변수

  void saveCreditToGraduate(int credits) async {
    await FlutterSecureStorage()
        .write(key: 'creditsToGraduate', value: credits.toString());
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    String studentIdString = await getStudentIdFromToken();
    int studentId = int.parse(studentIdString);
    var completionProvider =
    Provider.of<CompletionProvider>(context, listen: false);

    //await completionProvider.fetchCompletedSubjects(studentId);
    await completionProvider.loadSubjects();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => loadData());
  }

/*  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      String studentIdString = await getStudentIdFromToken();
      int studentId = int.parse(studentIdString);
      var completionProvider = Provider.of<CompletionProvider>(context, listen: false);

      await completionProvider.fetchCompletedSubjects(studentId);
      await completionProvider.loadSubjects();
    });
  }*/

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
          '나의 이수현황',
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
      body: Stack(
        children: [
          RefreshIndicator(onRefresh: loadData,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  //나의 이수현황 title
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 130,
                    width: double.infinity,
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
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '나의 이수현황',
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
                              'completion status',
                              style: TextStyle(
                                color: Color(0xff858585),
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  //입학년도와 전공유형 선택
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 110,
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: 30.0,
                      top: 14.0,
                      right: 14.0,
                      bottom: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xf6dce1ff),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                height: 30,
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Text('입학년도', style: TextStyle(color: Color(0xff5c6bb9), fontSize: 15, fontWeight: FontWeight.w600),)),
                            SizedBox(width: 2,),
                            Container(
                              height: 30,
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.white, borderRadius: BorderRadius.circular(10)),

                              child: DropdownButton<String>(
                                value: completionProvider.selectedYear,
                                items: completionProvider.admissionYears
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  completionProvider.setSelectedYear(newValue!);
                                },borderRadius: BorderRadius.circular(8),
                                dropdownColor: Color(0xffff5f5f5),
                                icon: Icon(Icons.arrow_drop_down_circle_rounded),
                                iconDisabledColor: const Color(0xff5f5f5),
                                iconEnabledColor: const Color(0xffC1D3FF),
                                iconSize: 25,
                                underline: SizedBox(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8,),
                        Row(
                          children: [
                            Container(
                                height: 30,
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Text('전공(이수)유형', style: TextStyle(color: Color(0xff5c6bb9), fontSize: 15, fontWeight: FontWeight.w600),)),
                            SizedBox(width: 2,),
                            Container(
                              height: 30,
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.white, borderRadius: BorderRadius.circular(10)),

                              child: DropdownButton<String>(
                                value: completionProvider.selectedMajor,
                                items: completionProvider
                                    .majorTypes[completionProvider.selectedYear]
                                    ?.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
                                  );
                                })?.toList(),
                                onChanged: (newValue) async {
                                  completionProvider.setSelectedMajor(newValue!);
                                  await completionProvider
                                      .getCreditToGraduate(); // getCreditToGraduate 메서드 호출
                                },
                                icon: Icon(Icons.arrow_drop_down_circle_rounded),
                                iconDisabledColor: const Color(0xff5f5f5),
                                iconEnabledColor: const Color(0xffC1D3FF),
                                iconSize: 25,
                                underline: SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    ,
                  ),
                  SizedBox(height: 30,),

                  //전공학점
                  Container(
                    child: Column(
                      children: [
                        Container(
                          height: 100,
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
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              //이수한 총 전공학점
                              FutureBuilder<int>(
                                future: Provider.of<CompletionProvider>(context,
                                    listen: false)
                                    .getTotalElectiveCredits(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<int> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return Text(
                                      '${snapshot.data}',
                                      style: TextStyle(
                                        color: Color(0xff2D0BB7),
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    );
                                  }
                                },
                              ),
                              //입학년도별 졸업기준학점
                              FutureBuilder<int?>(
                                  future: Provider.of<CompletionProvider>(context, listen: false).getCreditToGraduate(),
                                  builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('오류가 발생했습니다. ${snapshot.error}');
                                    } else {
                                      int? creditsToGraduate = snapshot.data;
                                      return Text(
                                        '/ ${creditsToGraduate ?? "66"} 학점',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      );
                                    }
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.0,),

                  //전공 이수과목 title & 이수과목 편집 버튼
                  Container(
                    height: 100,
                    padding: EdgeInsets.fromLTRB(30, 16, 16, 16),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                            color: Color(0xff858585),
                            width: 1.0,
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
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 8.0,
                                  ),
                                  const Text(
                                    'completed subject',
                                    style: TextStyle(
                                      color: Color(0xff858585),
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10.0,)
                          ],
                        ),
                        //이수과목 편집 버튼
                        Expanded(
                          child: Align(
                            //오른쪽 끝 정렬
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 40,
                              width: 110,
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
                                  padding: EdgeInsets.fromLTRB(7, 4, 7, 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  minimumSize: Size(100, 35),
                                  textStyle: TextStyle(
                                    fontSize: 16.0,
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

                  //이수한 전공기초과목 과목명
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.only(left: 30.0, right: 30.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xffF5F5F5),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xffA1A1A1),
                              offset: Offset(0, 3),
                              blurRadius: 2.0,
                              spreadRadius: 0.0)
                        ]),
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
                                          builder: (context) => MSmain()),
                                    );
                                  },
                                  child: const Text(
                                    '전공기초과목',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.0,),
                                Text(
                                  '${completionProvider.completedCompulsory.length}과목 | ${completionProvider.totalCompulsoryCredits}학점',
                                  style: TextStyle(
                                    color: Color(0xff686868),
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 8.0,
                            ),
                            Text(
                              '※ 전공기초학점은 교양학점으로 인정되어 전공학점에 포함되지 않음.',
                              style: TextStyle(
                                color: Color(0xff858585),
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15.0,),
                        Consumer<CompletionProvider>(
                          builder: (context, completionProvider, child) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: completionProvider.completedCompulsory
                                  .map((subject) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(subject.subjectName,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    )),
                              ))
                                  .toList(),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 20,),
                  //이수한 전공선택과목 과목명
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.only(left: 30.0, right: 30.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xffF5F5F5),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xffA1A1A1),
                              offset: Offset(0, 3),
                              blurRadius: 2.0,
                              spreadRadius: 0.0)
                        ]),

                    //이수한 전공선택과목 과목명
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MSmain()),
                                );
                              },
                              child: const Text(
                                '전공선택과목',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 8.0,
                            ),
                            Text(
                              '${completionProvider.completedElective.length}과목 | ',
                              style: TextStyle(
                                color: Color(0xff686868),
                                fontSize: 17.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            FutureBuilder<int>(
                              future: Provider.of<CompletionProvider>(context,
                                  listen: false)
                                  .getTotalElectiveCredits(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<int> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return Text(
                                    '${snapshot.data}학점',
                                    style: TextStyle(
                                      color: Color(0xff686868),
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 18.0,
                        ),
                        // Consumer를 사용해서 이수 과목 목록을 가져옵니다.
                        Consumer<CompletionProvider>(
                          builder: (context, completionProvider, child) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: completionProvider.completedElective
                                  .map((subject) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  subject.subjectName,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 70,),
                  //졸업가이드 보기 버튼
                  Center(
                    child: SizedBox(
                      height: 50,
                      width: 210,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) {
                              return ChangeNotifierProvider<CompletionProvider>.value(
                                value: Provider.of<CompletionProvider>(context,
                                    listen: false),
                                child: GraduationGuidePage(),
                              );
                            }),
                          );
                        },
                        child: const Text('나의 졸업가이드 보기',
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
                          minimumSize: Size(230, 60),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 140,),
                ],
              ),
            ),
          ),
          if(_isLoading)
            Center(
              child: CircularProgressIndicator(),
            )
        ],
      ),
    );
  }
}
