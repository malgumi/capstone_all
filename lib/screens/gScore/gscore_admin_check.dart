import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:capstone/screens/gScore/gscore_search_score.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AdminCheckPage extends StatefulWidget {
  @override
  _AdminCheckPageState createState() => _AdminCheckPageState();
}

class _AdminCheckPageState extends State<AdminCheckPage> {
  List<Map<String, dynamic>> userData = [];
  List<Map<String, dynamic>> filteredData = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gscore/allUser'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      List<Map<String, dynamic>> users = [];
      data.forEach((user) {
        users.add(user as Map<String, dynamic>);
      });
      setState(() {
        userData = users;
        filteredData = users; // 초기에는 모든 데이터를 보여줌
      });
    } else {
      throw Exception('Failed to fetch user data');
    }
  }

  Widget _buildPostItem(BuildContext context, dynamic user) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => searchScorePage(student_id: user['student_id'].toString()),
          ),
        );
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Container(
          width: 200.0,
          height: 70.0,
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white,
            border: Border.all(
              width: 2,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: Text(
                      user['student_id'].toString(),
                      style: TextStyle(
                        fontSize: 14.0,
                      )
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 37.0,),
                  child: Text(
                      user['name'].toString(),
                      style: TextStyle(
                        fontSize: 14.0,
                      )
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 50, right: 20),
                  child: Text(
                      user['grade'].toString(),
                      style: TextStyle(
                        fontSize: 14.0,
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _searchData() {
    final query = searchController.text;
    setState(() {
      filteredData = userData.where((user) {
        final studentId = user['student_id'].toString();
        return studentId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '학생 점수 조회',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xffC1D3FF),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 200.0,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller: searchController,
                            onChanged: (_) => _searchData(),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            ],
                            decoration: InputDecoration(
                              labelText: '학번검색',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        onPressed: _searchData,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.97,
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.7,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    width: double.infinity,
                    height: 50,
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.28,
                          alignment: Alignment.center,
                          child: Text(
                            "학번",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(width: 10),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.24,
                          alignment: Alignment.center,
                          child: Text(
                            "이름",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.22,
                          alignment: Alignment.center,
                          child: Text(
                            "학년",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        return _buildPostItem(context, filteredData[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}