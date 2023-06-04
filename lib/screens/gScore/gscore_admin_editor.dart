import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';


void main() {
  runApp(MaterialApp(
    title: '졸업인증제 항목 관리',
    home: GScoreEditor(),
  ));
}

class GScoreEditor extends StatefulWidget {
  const GScoreEditor({Key? key}) : super(key: key);

  @override
  _GScoreEditorState createState() => _GScoreEditorState();
}

class _GScoreEditorState extends State<GScoreEditor> {
  void initState() {
    super.initState();
    _fetchGsInfo();
    _getMaxScore();
  }

  @override
  Future<void> _fetchGsInfo() async {
    if (activityTypes.isEmpty) {
      final typeResponse =
      await http.get(Uri.parse('http://203.247.42.144:443/gScore/getType'));
      if (typeResponse.statusCode == 200) {
        final typeResult = jsonDecode(typeResponse.body);
        for (var typeItem in typeResult) {
          String gsinfoType = typeItem['gsinfo_type'];
          if (gsinfoType != '관리자승인' && !activityTypes.contains(gsinfoType)) {
            activityTypes.add(gsinfoType);
          }
        }
        setState(() {
          activityTypes;
          activityTypes.add("총점");
        });
      } else {
        throw Exception('Failed to load types');
      }
    }
  }

  Future<void> _fetchNamesAndScores(String selectedType) async {
    if (!activityNames.containsKey(selectedType)) {
      final encodedType = Uri.encodeComponent(selectedType);
      final infoResponse = await http.get(Uri.parse(
          'http://203.247.42.144:443/gScore/getInfoByType/$encodedType'));
      if (infoResponse.statusCode == 200) {
        final infoResult = jsonDecode(infoResponse.body);
        activityNames[selectedType] = {};
        for (var infoItem in infoResult) {
          String gsinfoName = infoItem['gsinfo_name'];
          int gsinfoScore = infoItem['gsinfo_score'];
          activityNames[selectedType]![gsinfoName] = gsinfoScore;
        }
        setState(() {
          activityNames;
        });
      } else {
        throw Exception('Failed to load names and scores');
      }
    }
  }

  List<String> activityTypes = [];
  Map<String, Map<String, int>> activityNames = {};

  TextEditingController _activityTypeController = TextEditingController();
  TextEditingController _activityNameController = TextEditingController();
  TextEditingController _activityScoreController = TextEditingController();
  TextEditingController _maxScoreController = TextEditingController();

  Map<String, dynamic> MaxScore = {};

  Future<void> _getMaxScore() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/maxScore'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final maxScoreTemp = jsonDecode(response.body);
      for (var item in maxScoreTemp) {
        String categoryName = item['max_category'];
        int categoryScore = item['max_score'];
        MaxScore[categoryName] = categoryScore;
      }
    } else {
      throw Exception('예외 발생');
    }
  }


  String? _selectedActivityType;
  String? _selectedActivityName;
  String? _selectedActivityScore;
  int? _selectedMaxScore;

  void addActivityName() async {
    String newActivityName = _activityNameController.text;
    int newActivityScore = int.tryParse(_activityScoreController.text) ?? 0;

    if (newActivityName == null || newActivityScore <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('올바른 이름 및 점수를 입력하세요.')));
    }
    else {
      if (!activityNames[_selectedActivityType]!.containsKey(newActivityName)) {
        final Map<String, dynamic> postData = {
          'category': _selectedActivityType,
          'name': newActivityName,
          'score': newActivityScore,
        };


        final response = await http.post(
          Uri.parse('http://203.247.42.144:443/gScore/insertInfo'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(postData),
        );

        if (response.statusCode == 201) {
          setState(() {
            activityNames[_selectedActivityType]![newActivityName] =
                newActivityScore;
            _activityNameController.clear();
            _activityScoreController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('항목이 추가되었습니다.')));
          });
        } else {
          print(response.statusCode);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('등록 실패: 서버 오류')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('동일한 이름의 항목이 이미 존재합니다.')));
      }
    }
  }

  void updateActivityName() async {
    String newActivityName = _activityNameController.text;
    int newActivityScore = int.tryParse(_activityScoreController.text) ?? 0;

    if (newActivityName == null || newActivityScore <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('올바른 이름 및 점수를 입력하세요.')));
    }
    else {
      final Map<String, dynamic> postData = {
        'category': _selectedActivityType,
        'name': _selectedActivityName,
        'newName': newActivityName,
        'newScore': newActivityScore
      };


      final response = await http.post(
        Uri.parse('http://203.247.42.144:443/gScore/updateInfo'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(postData),
      );

      if (response.statusCode == 201) {
        setState(() {
          activityNames[_selectedActivityType]?.remove(_selectedActivityName);
          activityNames[_selectedActivityType]![newActivityName] =
              newActivityScore;
          _selectedActivityName = null;
          _selectedActivityScore = null;
          _activityNameController.clear();
          _activityScoreController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('항목이 수정되었습니다.')));
        });
      } else {
        print(response.statusCode);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('수정 실패: 서버 오류')));
      }

    }
  }

  void removeActivityName() async{
    final Map<String, dynamic> postData = {
      'category': _selectedActivityType,
      'name': _selectedActivityName,
    };


    final response = await http.delete(
      Uri.parse('http://203.247.42.144:443/gScore/deleteInfo'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(postData),
    );

    if (response.statusCode == 201) {
      setState(() {
        activityNames[_selectedActivityType]
            ?.remove(_selectedActivityName);
        _selectedActivityName = null;
        _selectedActivityScore = null;
        _activityNameController.clear();
        _activityScoreController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('항목이 삭제되었습니다.')));
      });
    } else {
      print(response.statusCode);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: 서버 오류')));
    }


  }

  void updateActivityType() async {
    int newActivityTypeScore = int.tryParse(_maxScoreController.text) ?? 0;

    if (newActivityTypeScore <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('0보다 큰 값을 입력하세요.')));
    }
    else {
      final Map<String, dynamic> postData = {
        'category': _selectedActivityType,
        'newScore': newActivityTypeScore
      };

      final response = await http.post(
        Uri.parse('http://203.247.42.144:443/gScore/updateMaxScore'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(postData),
      );

      if (response.statusCode == 201) {
        setState(() {
          MaxScore[_selectedActivityType!] = newActivityTypeScore;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('항목이 수정되었습니다.')));
      }
      else {
        print(response.statusCode);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('수정 실패: 서버 오류')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '졸업인증제 항목 관리',
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: Center(
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: Text(
                    '활동종류 선택',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: activityTypes.map((type) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedActivityType = type;
                            _selectedActivityName = null;
                            _selectedActivityScore = null;
                            _selectedMaxScore = MaxScore[type];
                            _maxScoreController.text = MaxScore[type].toString();
                            _activityTypeController.text = type;
                            _fetchNamesAndScores(_activityTypeController.text);
                            _activityNameController.clear();
                            _activityScoreController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activityTypeController.text == type
                              ? Color(0xffbabfcc)
                              : Color(0xffC1D3FF),
                          elevation:
                          _activityTypeController.text == type ? 2.0 : 0.0,
                        ),
                        child: Text(type),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: Text(
                    '활동명 설정',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: EdgeInsets.all(8.0), // 내부 여백 설정
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: activityNames[_activityTypeController.text]
                              ?.entries
                              .map((entry) {
                            String name = entry.key;
                            int score = entry.value;
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                  _activityNameController.text == name ?
                                  Colors.blue : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if(_selectedActivityName == name){
                                    setState(() {
                                      _selectedActivityName = null;
                                      _selectedActivityScore = null;
                                      _activityNameController.clear();
                                      _activityScoreController.clear();
                                    });
                                  }
                                  else {
                                    setState(() {
                                      _selectedActivityName = name;
                                      _selectedActivityScore =
                                          score.toString();
                                      _activityNameController.text = name;
                                      _activityScoreController.text =
                                          score.toString();
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedActivityName == name
                                      ? Color(0xffbabfcc) : Color(0xffC1D3FF),
                                  elevation: _selectedActivityName == name ? 2.0 : 0.0,
                                ),
                                child: Text('$name ($score)'),
                              ),
                            );
                          }).toList() ??
                              <Widget>[],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _activityNameController,
                          decoration: InputDecoration(
                            labelText: '활동명',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextFormField(
                          controller: _activityScoreController,
                          decoration: InputDecoration(
                            labelText: '점수',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: Row(
                    children: [
                      SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedActivityType !=null && _selectedActivityName == null && _selectedActivityType != "총점") {
                            addActivityName();
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            _selectedActivityType !=null && _selectedActivityName == null &&_selectedActivityType != "총점"
                                ? Color(0xffC1D3FF)
                                : Color(0xffbabfcc),
                          ),
                        ),
                        child: Text('추가'),
                      ),
                      SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedActivityName != null) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('확인'),
                                  content: Text('정말로 수정하시겠습니까?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        updateActivityName();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('수정'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all<Color>(
                            _selectedActivityName != null
                                ? Color(0xffC1D3FF)
                                : Color(0xffbabfcc),
                          ),
                        ),
                        child: Text('수정'),
                      ),
                      SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedActivityName != null) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('확인'),
                                  content: Text('정말로 삭제하시겠습니까?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        removeActivityName();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('삭제'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all<Color>(
                            _selectedActivityName != null
                                ? Color(0xffC1D3FF)
                                : Color(0xffbabfcc),
                          ),
                        ),
                        child: Text('삭제'),
                      ),
                    ],
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: Text(
                    '최고점수 설정',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _activityTypeController,
                          readOnly: true, // readOnly를 true로 설정하여 읽기 전용으로 만듭니다.
                          decoration: InputDecoration(
                            labelText: '활동종류',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextFormField(
                          controller: _maxScoreController,
                          decoration: InputDecoration(
                            labelText: '점수',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.0),
                      ElevatedButton(

                        onPressed: () {
                          if (_selectedActivityType != null) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('확인'),
                                  content: Text('정말로 값을 수정하시겠습니까?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        updateActivityType();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('수정'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },

                        style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.all<Color>(
                            _selectedMaxScore == null
                                ? Color(0xffbabfcc) : Color(0xffC1D3FF),
                          ),
                        ),
                        child: Text('수정'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

