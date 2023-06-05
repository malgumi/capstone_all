import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddProfessorPage extends StatefulWidget {
  @override
  _AddProfessorPageState createState() => _AddProfessorPageState();
}

class _AddProfessorPageState extends State<AddProfessorPage> {
  TextEditingController proIdController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController majorController = TextEditingController();

  Future<void> addProfessor() async {
    final url = Uri.parse('http://203.247.42.144:443/prof/add');
    final body = jsonEncode({
      'pro_id': proIdController.text,
      'name': nameController.text,
      'email': emailController.text,
      'phone_num': phoneNumberController.text,
      'major': majorController.text,
    });

    final response = await http.post(url, body: body, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      // 성공적으로 추가되었을 때의 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공적으로 추가되었습니다'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추가 Error'),
        ),
      );
    }
  }

  @override
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: proIdController,
              decoration: InputDecoration(
                labelText: '사번',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '이름',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: '이메일',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: '전화번호',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: majorController,
              decoration: InputDecoration(
                labelText: '전공',
              ),
            ),
            SizedBox(height: 32.0),
            SizedBox(
              width: double.infinity,
              height: 30.0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 140.0), // 가로 여백 조정
                child: ElevatedButton(
                  onPressed: () {
                    addProfessor();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Color(0xffC1D3FF),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(Size.zero),
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero),
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text('추가'),
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
}
