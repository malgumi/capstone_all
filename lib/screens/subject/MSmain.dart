import 'package:capstone/drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/subject/subjectinfo.dart';
import 'package:capstone/main.dart';

void main() {
  runApp(MaterialApp(
    title: '과목 정보',
    home: MSmain(),
  ));
}

Future<List<List<Map<String, dynamic>>>> fetchSubjects() async {
  final response = await http.get(Uri.parse('http://3.39.88.187:3000/subject/'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as List<dynamic>;
    List<Map<String, dynamic>> subjects = List<Map<String, dynamic>>.from(data);

    List<Map<String, dynamic>> compulsorySubjects = [];
    List<Map<String, dynamic>> electiveSubjects = [];

    for (var subject in subjects) {
      if (subject['subject_division'] == 1) {
        compulsorySubjects.add(subject);
      } else if (subject['subject_division'] == 2) {
        electiveSubjects.add(subject);
      }
    }
    return [compulsorySubjects, electiveSubjects];
  } else {
    throw Exception('Failed to fetch subjects');
  }
}

Future<Map<String, dynamic>> fetchProfessor(String proId) async {
  final response = await http.get(Uri.parse('http://3.39.88.187:3000/prof/info?pro_id=$proId'));
  if (response.statusCode == 200) {
    final data = json.decode(response.body) as List<dynamic>;
    if (data.isNotEmpty) {
      final professorData = data[0] as Map<String, dynamic>;
      final name = professorData['name'];
      final proId = professorData['pro_id'];
      return {'name': name, 'pro_id': proId};
    } else {
      return {'name': 'Unknown', 'pro_id': ''}; // 교수명이 없는 경우 'Unknown'으로 설정
    }
  } else {
    throw Exception('Failed to fetch professor');
  }
}

class MSmain extends StatefulWidget {
  @override
  _MSmain createState() => _MSmain();
}

class _MSmain extends State<MSmain> {
  final TextEditingController _filter = TextEditingController();
  Future<List<List<Map<String, dynamic>>>> subjectsFuture = fetchSubjects();
  FocusNode focusNode = FocusNode();
  String search = ''; // 검색어를 저장할 변수

  _MSmain() {
    _filter.addListener(() {
      setState(() {
        search = _filter.text;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    subjectsFuture = fetchSubjects();
  }

  Future<void> refreshSubjects() async {
    setState(() {
      subjectsFuture = fetchSubjects();
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '과목 정보',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
        elevation: 0.0,
      ),
      drawer: MyDrawer(),
      body:  RefreshIndicator(
        onRefresh: refreshSubjects,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(40, 30, 0, 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child: Text(
                      "컴퓨터공학과 전공과목",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  /*
                  //조교페이지 추가탭
                  SizedBox(
                    width: 110.0, // 원하는 너비로 설정
                    height: 30.0, // 원하는 높이로 설정
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 40, 0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddProfessorPage()),
                          );
                        },
                        child: Text('과목 추가',
                          style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Colors.white,),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo, // 배경 색상 변경
                          padding: EdgeInsets.symmetric(vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                   */
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(40, 5, 0, 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    child: Text(
                      "major subject",
                      style: TextStyle(
                        color: Color(0xff848484),
                        fontSize: 14,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 검색창 구현
            Container(
              padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 6,
                    child: TextField(
                      textAlign: TextAlign.center,
                      focusNode: focusNode,
                      style: TextStyle(
                        fontSize: 15,
                      ),
                      autofocus: true,
                      controller: _filter,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black12,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.black54,
                          size: 20,
                        ),
                        suffixIcon: focusNode.hasFocus
                            ? IconButton(
                          icon: Icon(
                            Icons.cancel,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _filter.clear();
                              search = "";
                            });
                          },
                        )
                            : Container(),
                        hintText: '과목명 또는 교수명을 입력하세요',
                        labelStyle: TextStyle(color: Colors.black),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius:
                            BorderRadius.all(Radius.circular(10))),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius:
                            BorderRadius.all(Radius.circular(10))),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                            borderRadius:
                            BorderRadius.all(Radius.circular(10))),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(40, 5, 0, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    child: Text(
                      "전공기초과목  ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    child: Text(
                      "compulsory subject",
                      style: TextStyle(
                        color: Color(0xff848484),
                        fontSize: 14,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(40, 10, 40, 10),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child:
                FutureBuilder<List<List<Map<String, dynamic>>>>(
                  future: subjectsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // 데이터를 가져오는 데 성공한 경우
                      List<Map<String, dynamic>> subjects = snapshot.data![0];
                      if (search.isNotEmpty) {
                        // 검색어가 있을 때 데이터를 필터링하여 표시
                        subjects = subjects.where((subject) =>
                        subject['subject_name'].toString().toLowerCase().contains(search.toLowerCase()) ||
                            subject['pro_id'].toString().toLowerCase().contains(search.toLowerCase())).toList();
                        //subject['subject_name'].toString() == search).toList();
                      }
                      if (subjects.isEmpty) {
                        // 필터링된 결과가 없는 경우
                        return Center(child: Text('검색결과를 찾지 못했습니다'));
                      }
                      return Scrollbar(
                          child: ListView.builder(
                            itemCount: subjects.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '    학수번호',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        '과목명',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        '교수명    ',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final subject = subjects[index - 1];

                              if (search.isNotEmpty && !subject['subject_name'].toString().toLowerCase().contains(search.toLowerCase()) && !subject['pro_id'].toString().toLowerCase().contains(search.toLowerCase())) {
                                // 검색어가 있고 현재 항목의 subject_name과 pro_id가 검색어와 일치하지 않으면 표시하지 않음
                                return Container();
                              }
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                title: GestureDetector(
                                  onTap: () {
                                    // 행을 누르면 과목 상세페이지로 이동
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubjectInfo(
                                          subjectId: subject['subject_id'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      color: Colors.white,
                                      border: Border.all(
                                        width: 2,
                                        color: Colors.grey.withOpacity(0.5),
                                      ),
                                    ),
                                    child: FutureBuilder<Map<String, dynamic>>(
                                      future: fetchProfessor(subject['pro_id'].toString()),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final professor = snapshot.data!;
                                          final proId = professor['pro_id'];
                                          final name = professor['name'];

                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subject['subject_id'].toString(),
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8.0),
                                              Text(subject['subject_name'].toString(),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8.0),
                                              Text(
                                                subject['pro_id'].toString(),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                            ],
                                          );
                                        } else if (snapshot.hasError) {

                                          return Text('Failed to fetch professor');
                                        } else {
                                          return Text('Loading professor...');}},
                                    ),
                                  ), // 추가적인 과목 정보 표시를 위한 코드 작성
                                ),
                              );
                            },
                          )
                      );
                    } else if (snapshot.hasError) {
                      // 데이터를 가져오는 데 실패한 경우
                      return Center(child: Text('Failed to fetch subjects'));
                    } else {
                      // 데이터를 가져오는 중인 경우
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),

            ),
            Container(
              padding: EdgeInsets.fromLTRB(40, 20, 0, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    child: Text(
                      "전공선택과목  ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    child: Text(
                      "elective subject",
                      style: TextStyle(
                        color: Color(0xff848484),
                        fontSize: 14,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(40, 10, 40, 10),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: FutureBuilder<List<List<Map<String, dynamic>>>>(
                  future: subjectsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // 데이터를 가져오는 데 성공한 경우
                      List<Map<String, dynamic>> subjects = snapshot.data![1];
                      if (search.isNotEmpty) {
                        // 검색어가 있을 때 데이터를 필터링하여 표시
                        subjects = subjects.where((subject) =>

                        subject['subject_name']
                            .toString()
                            .toLowerCase()
                            .contains(search.toLowerCase()) ||
                            subject['pro_id']
                                .toString()
                                .toLowerCase()
                                .contains(search.toLowerCase()))
                            .toList();
                      }
                      if (subjects.isEmpty) {
                        // 필터링된 결과가 없는 경우
                        return Center(child: Text('검색결과를 찾지 못했습니다'));
                      }
                      return Scrollbar(
                          child: ListView.builder(
                            itemCount: subjects.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '    학수번호',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        '과목명',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        '교수명    ',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final subject = subjects[index - 1];
                              if (search.isNotEmpty &&
                                  !subject['subject_name']
                                      .toString()
                                      .toLowerCase()
                                      .contains(search.toLowerCase()) &&
                                  !subject['pro_id']
                                      .toString()
                                      .toLowerCase()
                                      .contains(search.toLowerCase())) {
                                // 검색어가 있고 현재 항목의 subject_name과 pro_id가 검색어와 일치하지 않으면 표시하지 않음
                                return Container();
                              }

                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                title: GestureDetector(
                                  onTap: () {
                                    // 행을 누르면 수정 페이지로 이동합니다.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubjectInfo(
                                          subjectId: subject['subject_id'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      color: Colors.white,
                                      border: Border.all(
                                        width: 2,
                                        color: Colors.grey.withOpacity(0.5),
                                      ),
                                    ),
                                    child: FutureBuilder<Map<String, dynamic>>(
                                      future: fetchProfessor(subject['pro_id'].toString()),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final professor = snapshot.data!;

                                          return Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment
                                                .start,
                                            children: [
                                              Text(
                                                subject['subject_id']
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8.0),
                                              Text(
                                                subject['subject_name']
                                                    .toString(),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8.0),
                                              Text(
                                                subject['pro_id'].toString(),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                            ],
                                          );
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Failed to fetch professor');
                                        } else {
                                          return Text('Loading professor...');
                                        }
                                      },
                                    ),
                                  ),

                                ), // 추가적인 교수 정보 표시를 위한 코드 작성
                              );
                            },
                          )
                      );
                    } else if (snapshot.hasError) {
                      // 데이터를 가져오는 데 실패한 경우
                      return Center(child: Text('Failed to fetch subjects'));
                    } else {
                      // 데이터를 가져오는 중인 경우
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}