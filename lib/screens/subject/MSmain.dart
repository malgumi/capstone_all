import 'package:capstone/drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:capstone/screens/subject/CS_Tab.dart';
import 'package:capstone/screens/subject/ES_Tab.dart';

// [과목정보 메인]-학생

void main() {
  runApp(MaterialApp(
    title: '과목 정보',
    home: MSmain(),
  ));
}

Future<List<List<Map<String, dynamic>>>> fetchSubjects() async {
  final response = await http.get(Uri.parse('http://203.247.42.144:443/subject/'));

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: '전공기초',
              ),
              Tab(
                text: '전공선택',
              ),
            ],
          ),
        ),
        drawer: MyDrawer(),
        body: TabBarView(
          children: [
            CStab(),
            EStab(),
          ],
        ),
      ),
    );
  }
}