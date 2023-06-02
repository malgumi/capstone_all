import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:core';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:capstone/screens/completion/subject_model.dart';
import 'package:capstone/screens/completion/mycompletion.dart';
import 'package:capstone/screens/completion/completed_subject_select.dart';


//Provider을 이용해 이수 상태를 관리함


// 이수과목 모델
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

class CompletionProvid extends ChangeNotifier {
  final storage = new FlutterSecureStorage();

  List<Subject> _completedCompulsory = []; //선언과 동시에 초기화해줘야 함.
  List<Subject> _completedElective = [];

  List<Subject> get completedCompulsory => _completedCompulsory;
  List<Subject> get completedElective => _completedElective;


  //JWT 토큰에서 학생 ID를 가져오는 메서드 - 학생ID로 사용자를 식별해 이수정보를 저장하기 위함.
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



  //과목을 추가하는 메서드
  void addSubject(Subject subject) {
    if (subject.subjectDivision == 1) {
      _completedCompulsory.add(subject);
    } else if (subject.subjectDivision == 2) {
      _completedElective.add(subject);
    }
    notifyListeners();
  }
  /*추가된 과목들을 addSubject(Subject subject) 함수를 통해
  _completedCompulsory나 _completedElective 리스트에 추가함*/


  //과목을 삭제하는 메서드
  void removeSubject(Subject subject) {
    if (subject.subjectDivision == 1) {
      _completedCompulsory.remove(subject);
    } else if (subject.subjectDivision == 2) {
      _completedElective.remove(subject);
    }
    notifyListeners();
  }



  // SecureStorage에 이수한 과목을 저장하는 메서드
  Future<void> saveSubjects() async {
    List<Subject> allSubjects = []
      ..addAll(_completedCompulsory)
      ..addAll(_completedElective);

    await storage.write(
        key: 'completedSubjects',
        value: jsonEncode(
            allSubjects.map((subject) => subject.toJson()).toList()));
  }
  /*saveSubjects() 함수를 통해 이들 리스트의 모든 과목들이
  JSON 형태로 인코딩되어 FlutterSecureStorage에 저장됨*/


  // SecureStorage에서 기존에 저장된 이수한 과목을 불러오는 메서드
  Future<void> loadSubjects() async {
    String? data = await storage.read(key: 'completedSubjects');
    if (data != null) {
      print('기존에 저장된 이수한 과목을 불러오는 메서드 loadSubjects() Data: $data'); //로깅
      var subjectData = jsonDecode(data) as List;
      _completedCompulsory = subjectData
          .map((item) => Subject.fromJson(item))
          .where((subject) => subject.subjectDivision == 1)
          .toList();
      _completedElective = subjectData
          .map((item) => Subject.fromJson(item))
          .where((subject) => subject.subjectDivision == 2)
          .toList();
      notifyListeners();
    }
  }
 /* loadSubjects()를 호출하여 SecureStorage에서 데이터를 로드하면
  _completedCompulsory와 _completedElective 리스트는 SecureStorage에 저장된 데이터로 업데이트
*/


  //서버에 이수한 과목 정보를 보내는 메서드 - 이수과목 저장
  Future<void> saveCompletedSubjects() async {
    final url = Uri.parse('http://203.247.42.144:443/user/required/add');
    final studentId = await getStudentIdFromToken();

    final List<Map<String, dynamic>> data = [];
    for (final subject in _completedCompulsory) {
      data.add({
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      });
    }
    for (final subject in _completedElective) {
      data.add({
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      });
    }

    final body = json.encode(data);
    print('이수한 과목 정보를 보내는 saveCompletedSubjects 메서드 Request body: $body'); // 로깅
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
    } else {
      print('서버 응답: ${response.body}'); // 에러 발생 시 서버의 응답을 출력합니다.
    }
  }


  //서버에서 최신 데이터를 가져와 로컬 저장소를 업데이트 하는 메서드
  Future<void> fetchCompletedSubjects(int studentId) async {
    final Uri completedSubjectsUrl =
    Uri.parse('http://203.247.42.144:443/user/required?student_id=$studentId');
    final http.Response completedSubjectsResponse =
    await http.get(completedSubjectsUrl);

    if (completedSubjectsResponse.statusCode == 200) {
      final List<dynamic> completedSubjectsData =
      json.decode(completedSubjectsResponse.body);

      List<Subject> completedSubjects = [];

      for (var item in completedSubjectsData) {
        final CompletedSubjects completedSubject =
        CompletedSubjects.fromJson(item);

        final Uri subjectUrl = Uri.parse(
            'http://3.39.88.187:3000/user/required/subject?subject_id=${completedSubject.subjectId}');

        var subjectResponse = await http.get(subjectUrl);
        if (subjectResponse.statusCode == 200) {
          final List<dynamic> subjectData =
          json.decode(subjectResponse.body);
          Subject subject = Subject.fromJson(subjectData[0]);
          completedSubjects.add(subject);
        } else {
          throw Exception(
              'Failed to load subject data: ${subjectResponse.statusCode}');
        }
      }

      _completedCompulsory = completedSubjects.where((subject) => subject.subjectDivision == 1).toList();
      _completedElective = completedSubjects.where((subject) => subject.subjectDivision == 2).toList();

      // SecureStorage에 이수한 과목 정보를 저장
      saveSubjects();

      notifyListeners();
    } else {
      throw Exception(
          'Failed to load completed subjects: ${completedSubjectsResponse.statusCode}');
    }
  }



  // DELETE 요청을 이용해 서버에서 이수과목 정보를 삭제하는 메서드
  //서버에서 단일 이수과목을 삭제하는 메서드
  Future<void> deleteCompletedSubject(int studentId, int subjectId, int proId) async {
    await deleteCompletedSubjects(studentId, [{
      'subject_id': subjectId,
      'pro_id': proId
    }]);
  }

  //서버에서 복수의 이수과목을 삭제하는 메서드
  Future<void> deleteCompletedSubjects(int studentId, List<Map<String, dynamic>> subjects) async {
    final url = Uri.parse('http://203.247.42.144:443/user/required/delete');

    final List<Map<String, dynamic>> body = subjects.map((subject) => {
      'student_id': studentId,
      ...subject,
    }).toList();

    print('이수한 과목 정보를 삭제하는 deleteCompletedSubjects 메서드 Request body: ${jsonEncode(body)}'); // 로깅
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('서버 응답: ${response.body}'); // 서버의 응답을 출력합니다.
    } else {
      print('서버 응답: ${response.body}'); // 에러 발생 시 서버의 응답을 출력합니다.
    }
  }

  // 과목 추가
  Future<bool> addSubjectToServer(Subject subject) async {
    final studentId = await getStudentIdFromToken();

    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/user/required/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  // 과목 삭제
  Future<bool> removeSubjectFromServer(Subject subject) async {
    final studentId = await getStudentIdFromToken();

    final response = await http.delete(
      Uri.parse('http://203.247.42.144:443/user/required/delete'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'student_id': studentId,
        'subject_id': subject.subjectId,
        'pro_id': subject.proId,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }


  // 모든 과목을 반환하는 메서드 - Provider가 관리하고 있는 모든 이수한 과목을 가져오기
  List<Subject> getAllSubjects() {
    return [..._completedCompulsory, ..._completedElective];
  }


  //전공기초과목 업데이트
  void updateCompulsory(List<Subject> newSubjects) {
    //새로운 과목 리스트가 기존의 _completedCompulsory와 다를 때만 업데이트
    if (_completedElective != newSubjects) {
      _completedElective = newSubjects;
      notifyListeners();
    }
  }


  //전공선택과목 업데이트
  void updateElective(List<Subject> newSubjects) {
    if (_completedElective != newSubjects) {
      _completedElective = newSubjects;
      notifyListeners();
    }
  }



}


/*//총 전공학점
class TotalCredit extends ChangeNotifier {
  int _totalCredit = 0;

  int get totalCredit => _totalCredit;

  void setTotalCredit(int value) {
    _totalCredit = value;
    notifyListeners();  // 학점이 변경되었으므로 관련된 위젯들에게 알립니다.
  }
}*/



//추후에 23학번 이수유형별 전공학점 관리



