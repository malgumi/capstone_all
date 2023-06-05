import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/drawer.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/completion/completion_provider.dart';
import 'package:capstone/screens/completion/subject_model.dart';

// 이수과목 선택 페이지
class CompletedSubjectSelectPage extends StatefulWidget {
  @override
  _CompletedSubjectSelectPageState createState() =>
      _CompletedSubjectSelectPageState();
}

class _CompletedSubjectSelectPageState
    extends State<CompletedSubjectSelectPage> {
  List<Subject> _subjects = [];
  List<MultiSelectItem<Subject>> _compulsoryItems = [];
  List<MultiSelectItem<Subject>> _electiveItems = [];
  List<Subject> _compulsorySelections = [];
  List<Subject> _electiveSelections = [];
  List<Subject> compulsorySubjects = [];
  List<Subject> electiveSubjects = [];

  @override
  void initState() {
    super.initState();
    //UI 렌더링이 완료된 후에 Provider의 데이터를 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSubjects();
    });
  }

  //사용자 인증 jwt 토큰 방식
  Future<String> getStudentIdFromToken() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Token is not found');
    }

    final jwtToken =
    JwtDecoder.decode(token); // use jwt_decoder package to decode the token

    return jwtToken['student_id']; // ensure the token includes 'student_id'
  }

  // 과목정보 불러오기
  Future<void> fetchSubjects() async {
    final response =
    await http.get(Uri.parse('http://203.247.42.144:443/subject/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _subjects = data.map((item) => Subject.fromJson(item)).toList();

      //여기서 _compulsoryItems 과 _electiveItems 업데이트
      _compulsoryItems = _subjects
          .where((subject) => subject.subjectDivision == 1)
          .map((subject) =>
          MultiSelectItem<Subject>(subject, subject.subjectName))
          .toList();

      _electiveItems = _subjects
          .where((subject) => subject.subjectDivision == 2)
          .map((subject) =>
          MultiSelectItem<Subject>(subject, subject.subjectName))
          .toList();

      setState(() {});
    } else {
      throw Exception('Failed to load subjects');
    }
  }

  @override
  Widget build(BuildContext context) {
    var completionProvider =
    Provider.of<CompletionProvider>(context, listen: false);
    return Scaffold(
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
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              //이수한 과목을 선택하세요 문구
              Container(
                child: const Text(
                  '이수한 과목을 선택하세요!',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 30),

              //전기 전선 MultiSelectBottomSheetField
              Column(
                children: [
                  //전공기초과목 field
                  Container(
                    padding: EdgeInsets.all(10.0),
                    margin: EdgeInsets.only(left: 15.0, top: 15.0, bottom: 7.0, right: 15.0),
                    decoration: BoxDecoration(
                      color: const Color(0xffF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xff858585),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        MultiSelectBottomSheetField(
                          initialChildSize: 0.4,
                          listType: MultiSelectListType.CHIP,
                          searchable: false,
                          buttonText: const Text(
                            "전공기초과목",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: const Text(
                              "전공기초과목",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          items: _compulsoryItems,
                          initialValue: completionProvider.completedCompulsory,
                          onConfirm: (values) {
                            _compulsorySelections = values.cast<Subject>();
                            //이수한 전공기초과목 업데이트
                            completionProvider
                                .updateCompulsory(_compulsorySelections);

                            // 추가된 과목들 처리
                            for (Subject subject in _compulsorySelections) {
                              completionProvider.addSubject(subject);
                            }
                            // 삭제된 과목들 처리
                            for (Subject subject
                            in completionProvider.completedCompulsory) {
                              if (!_compulsorySelections.contains(subject)) {
                                completionProvider.removeSubject(subject);
                              }
                            }
                            print('선택한 전공기초과목: $_compulsorySelections');
                          },
                          selectedColor: Color(0xffF29811),
                          selectedItemsTextStyle:
                          TextStyle(color: Color(0xffffffff)),
                          chipDisplay: MultiSelectChipDisplay(
                            chipColor: Color(0xffFFBC58),
                            textStyle: TextStyle(color: Colors.black),
                            onTap: (value) {
                              setState(() {
                                _compulsorySelections.remove(value as Subject);
                                Provider.of<CompletionProvider>(context,
                                    listen: false)
                                    .removeSubject(value as Subject);
                              });
                            },
                          ),
                        ),
                        //아무 전공기초과목도 선택하지 않았을 경우 '선택안함' 표시 -실시간 반영
                        Consumer<CompletionProvider>(
                          builder: (context, completionProvider, child) {
                            return completionProvider.completedCompulsory ==
                                null ||
                                completionProvider
                                    .completedCompulsory.isEmpty
                                ? Container(
                              padding: EdgeInsets.all(10),
                              alignment: Alignment.center,
                              child: Text(
                                "선택안함",
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                                : Container(
                              height: 30,
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10.0),
                    margin: EdgeInsets.all(5.0),
                    child: Text(
                      '※ 19~20학번 학생은 컴퓨터개론을 선택하시면 전공선택과목을 이수한 것으로 인정되어 전공학점에 포함됩니다.',
                      style: TextStyle(
                        color: Color(0xff858585),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  //전공선택과목 field
                  Container(
                    padding: EdgeInsets.all(10.0),
                    margin: EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      color: const Color(0xffF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xff858585),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        // 전공선택과목 BottomSheet
                        MultiSelectBottomSheetField(
                          initialChildSize: 0.4,
                          maxChildSize: 0.6,
                          listType: MultiSelectListType.CHIP,
                          searchable: true,
                          searchHint: '과목명을 입력하세요',
                          buttonText: const Text(
                            "전공선택과목",
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Text(
                              "전공선택과목",
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          items: _electiveItems,
                          initialValue: completionProvider.completedElective,
                          onConfirm: (values) {
                            _electiveSelections = values.cast<Subject>();
                            // 이수한 전공선택과목 업데이트
                            completionProvider
                                .updateElective(_electiveSelections);

                            // 추가된 과목들 처리
                            for (Subject subject in _electiveSelections) {
                              completionProvider.addSubject(subject);
                            }
                            // 삭제된 과목들 처리
                            for (Subject subject
                            in completionProvider.completedElective) {
                              if (!_electiveSelections.contains(subject)) {
                                completionProvider.removeSubject(subject);
                              }
                            }
                            print('선택한 전공선택과목: $_electiveSelections');
                          },
                          //전공선택과목 선택할 때의 chip컬러
                          selectedColor: Color(0xff89AAFF),
                          selectedItemsTextStyle:
                          TextStyle(color: Color(0xffffffff)),
                          chipDisplay: MultiSelectChipDisplay(
                            //전공선택과목 선택 후 chip컬러
                            chipColor: Color(0xffC1D3FF),
                            textStyle: TextStyle(color: Colors.black),
                            onTap: (value) {
                              setState(() {
                                _electiveSelections.remove(value as Subject);
                                Provider.of<CompletionProvider>(context,
                                    listen: false)
                                    .removeSubject(value as Subject);
                              });
                            },
                          ),
                        ),

                        //아무 전공선택과목을 선택하지 않았을 때 선택안함 표시
                        Consumer<CompletionProvider>(
                          builder: (context, completionProvider, child) {
                            return completionProvider.completedElective ==
                                null ||
                                completionProvider.completedElective.isEmpty
                                ? Container(
                              padding: EdgeInsets.all(10),
                              alignment: Alignment.center,
                              child: Text(
                                "선택안함",
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                                : Container();
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 80),

              //저장버튼
              ElevatedButton(
                onPressed: () async {
                  // 선택한 모든 과목을 로컬에 저장
                  await completionProvider.saveSubjects();

                  // 다음 페이지로 이동합니다.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompletionStatusPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xffffff),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  backgroundColor: const Color(0xff341F87),
                  minimumSize: Size(100, 50),
                ),
                child: Text('저장'),
              ),

              SizedBox(height: 50.0),
            ],
          ),
        ),
      ),
    );
  }
}
