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

  //모든 과목정보 불러오기
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
                    fontSize: 22.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 30),

              //과목에 대한 공지사항
              Container(
                padding: EdgeInsets.all(10.0),
                margin: EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: const Color(0xfff5f5f5),
                  border: Border.all(
                    color: const Color(0xff858585),
                    width: 2.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '※ 공지사항',
                      style: TextStyle(
                        color: Color(0xff565656),
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10,),
                    Text(
                      '19~22학번 학생은 컴퓨터개론을 선택하시면 전공선택과목을 이수한 것으로 인정되어 전공학점에 포함됩니다.',
                      style: TextStyle(
                        color: Color(0xff858585),
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30,),

              //전공과목 선택 Field
              Column(
                children: [
                  //전공기초과목 field
                  CompulsoryMultiSelect(
                    compulsoryItems: _compulsoryItems,  // _compulsoryItems should be a List<MultiSelectItem<Subject>>
                  ),
                  SizedBox(height: 20),

                  //전공선택과목 field
                  ElectiveMultiSelect(
                    electiveItems: _electiveItems,  // _electiveItems should be a List<MultiSelectItem<Subject>>
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
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xffffffff),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  backgroundColor: const Color(0xff341F87),
                  minimumSize: Size(100, 50),
                ),
                child: Text('저장'),
              ),

              SizedBox(height: 100.0),
            ],
          ),
        ),
      ),
    );
  }
}



//전공기초과목 필드
class CompulsoryMultiSelect extends StatefulWidget {
  final List<MultiSelectItem<Subject>> compulsoryItems;

  CompulsoryMultiSelect({required this.compulsoryItems});

  @override
  _CompulsoryMultiSelectState createState() => _CompulsoryMultiSelectState();
}

class _CompulsoryMultiSelectState extends State<CompulsoryMultiSelect> {
  List<Subject> _compulsorySelections = [];
  List<MultiSelectItem<Subject>> _compulsoryItems = [];
  List<Subject> compulsorySubjects = [];

  @override
  Widget build(BuildContext context) {
    var completionProvider = Provider.of<CompletionProvider>(context, listen: false);
    return Container(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.only(
          left: 15.0, top: 15.0, bottom: 7.0, right: 15.0),
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black,
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
                fontSize: 24.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.all(10.0),
              child: const Text(
                "전공기초과목",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            items: widget.compulsoryItems,
            initialValue: completionProvider.completedCompulsory,
            onConfirm: (values) {
              _compulsorySelections = values.cast<Subject>();
              Provider.of<CompletionProvider>(context, listen: false)
                  .updateCompulsory(_compulsorySelections);

            },
            selectedColor: Color(0xffF29811),
            selectedItemsTextStyle:
            TextStyle(color: Color(0xffffffff), fontWeight: FontWeight.w600),
            chipDisplay: MultiSelectChipDisplay(
              chipColor: Color(0xffFFBC58),
              textStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              onTap: (value) {
                setState(() {
                  _compulsorySelections.remove(value as Subject);
                  var provider = Provider.of<CompletionProvider>(context, listen: false);
                  provider.removeSubject(value as Subject);

                  // 업데이트 함수 호출
                  provider.updateElective(List<Subject>.from(_compulsorySelections));
                });
              },

            ),
          ),
        ],
      ),
    );
  }
}







//전공선택과목 필드
class ElectiveMultiSelect extends StatefulWidget {
  final List<MultiSelectItem<Subject>> electiveItems;

  ElectiveMultiSelect({required this.electiveItems});

  @override
  _ElectiveMultiSelectState createState() => _ElectiveMultiSelectState();
}

class _ElectiveMultiSelectState extends State<ElectiveMultiSelect> {
  List<Subject> _electiveSelections = [];
  List<MultiSelectItem<Subject>> _electiveItems = [];
  List<Subject> compulsorySubjects = [];
  List<Subject> electiveSubjects = [];

  @override
  Widget build(BuildContext context) {
    var completionProvider = Provider.of<CompletionProvider>(context, listen: false);
    return Container(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black,
          width: 1.5,
        ),
      ),
      child: Column(
        children: <Widget>[
          MultiSelectBottomSheetField(
            initialChildSize: 0.6,
            maxChildSize: 1.2,
            listType: MultiSelectListType.CHIP,
            searchable: true,
            searchHint: '과목명을 입력하세요',
            buttonText: const Text(
              "전공선택과목",
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                "전공선택과목",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            items: widget.electiveItems,
            initialValue: completionProvider.completedElective,
            onConfirm: (values) {
              _electiveSelections = values.cast<Subject>();
              Provider.of<CompletionProvider>(context, listen: false)
                  .updateElective(_electiveSelections);

            },
            //전공선택과목 선택할 때의 chip컬러
            selectedColor: Color(0xff89AAFF),
            selectedItemsTextStyle:
            TextStyle(color: Color(0xffffffff),
                fontWeight: FontWeight.w600),
            chipDisplay: MultiSelectChipDisplay(
              //전공선택과목 선택 후 chip컬러
              chipColor: Color(0xffC1D3FF),
              textStyle: TextStyle(color: Colors.black,
                  fontWeight: FontWeight.w600),
              onTap: (value) {
                setState(() {
                  _electiveSelections.remove(value as Subject);
                  var provider = Provider.of<CompletionProvider>(context, listen: false);
                  provider.removeSubject(value as Subject);

                  // 업데이트 함수 호출
                  provider.updateElective(List<Subject>.from(_electiveSelections));
                });
              },

            ),
          ),
          // ...
        ],
      ),
    );
  }
}


