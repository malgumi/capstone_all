import 'package:capstone/drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/prof/prof_add.dart';
import 'package:capstone/screens/prof/prof_edit.dart';

void main() {
  runApp(MaterialApp(
    title: '교수 정보 관리',
    home: ProfProfile(),
  ));
}

Future<List<Map<String, dynamic>>> fetchProfessors() async {
  final response = await http.get(Uri.parse('http://203.247.42.144:443/prof/'));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception('Failed to fetch professors');
  }
}

class ProfProfile extends StatefulWidget {
  @override
  _ProfProfile createState() => _ProfProfile();
}

class _ProfProfile extends State<ProfProfile> {
  Future<List<Map<String, dynamic>>> professorsFuture = fetchProfessors();

  String searchId = ''; // 검색어를 저장할 변수

  @override
  void initState() {
    super.initState();
    professorsFuture = fetchProfessors();
  }

  Future<void> refreshProfessors() async {
    setState(() {
      professorsFuture = fetchProfessors();
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '교수 정보 관리',
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
      body:  RefreshIndicator(
        onRefresh: refreshProfessors,
        child: Column(
         children: [
          SizedBox(
            height: 56.0,
            width: 355.0,
            child: Container(
              margin: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Color(0xFF858585),
                  width: 2.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: TextField(
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '사번을 입력하세요',
                            border: InputBorder.none,
                          ),
                            onChanged: (value) {
                              setState(() {
                                searchId = value;
                              });
                          }
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          searchId = ''; // 검색어 초기화
                        });
                        // 검색 버튼을 눌렀을 때의 동작 구현
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.0),
           Padding(
             padding: const EdgeInsets.fromLTRB(20.0, 8.0, 0.0, 8.0),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Padding(
                   padding: const EdgeInsets.only(right: 16.0),
                   child: Text(
                     '교수 정보',
                     style: TextStyle(
                       fontSize: 20.0,
                       fontWeight: FontWeight.bold,
                       color: Colors.black,
                     ),
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.only(right: 0),
                   child: Text(
                     'Professor Information',
                     style: TextStyle(
                       fontSize: 18.0,
                       color: Color(0xFF858585),
                     ),
                   ),
                 ),
                 Expanded(
                   child: Align(
                     alignment: Alignment.centerRight,
                     child: Container(
                       margin: EdgeInsets.only(right: 16.0),
                       child: ElevatedButton(
                         onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => AddProfessorPage()),
                           );
                         },
                         child: Text(
                           '추가',
                           style: TextStyle(
                             fontSize: 18.0,
                             fontWeight: FontWeight.bold,
                             color: Colors.white,
                           ),
                         ),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Color(0xffC1D3FF), // 배경 색상 변경
                           padding: EdgeInsets.symmetric(vertical: 6.0),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(0.0),
                           ),
                         ),
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           ),



           // 기본 화면 위젯과 검색 위젯 사이의 간격 조정
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(20.0, 10, 20.0, 0.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
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
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: professorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // 데이터를 가져오는 데 성공한 경우
                    List<Map<String, dynamic>> professors = snapshot.data!;
                    if (searchId.isNotEmpty) {
                      // 검색어가 있을 때 데이터를 필터링하여 표시
                      professors = professors.where((professor) =>
                      professor['pro_id'].toString() == searchId).toList();
                    }
                    if (professors.isEmpty) {
                      // 필터링된 결과가 없는 경우
                      return Center(child: Text('No professors found'));
                    }
                    return Scrollbar(
                        child: ListView.builder(
                          itemCount: professors.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Text(
                                          '사번',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '이름',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '전화번호',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final professor = professors[index - 1];
                            if (searchId.isNotEmpty && professor['pro_id'].toString() != searchId) {
                              // 검색어가 있고 현재 항목의 pro_id가 검색어와 일치하지 않으면 표시하지 않음
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
                                      builder: (context) => EditProfessorPage(
                                       professorId: professor['pro_id'].toString(),
                                      ),
                                    ),
                                  );
                                },
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 15.0),
                                      child: Text(
                                        professor['pro_id'].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 55.0),
                                      child: Text(
                                        professor['name'],
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      professor['phone_num'],
                                      overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ), // 추가적인 교수 정보 표시를 위한 코드 작성
                            );
                          },
                        )
                    );
                  } else if (snapshot.hasError) {
                    // 데이터를 가져오는 데 실패한 경우
                    return Center(child: Text('Failed to fetch professors'));
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