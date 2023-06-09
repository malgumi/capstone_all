import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:capstone/screens/gScore/gscore_list_screen.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(MaterialApp(
    title: '신청글 조회/수정',
  ));
}

class GScoreApcCt extends StatefulWidget {
  final dynamic post;

  GScoreApcCt({required this.post});

  @override
  _GScoreApcCtState createState() => _GScoreApcCtState();
}

//메인
class _GScoreApcCtState extends State<GScoreApcCt> {

  String? _selectedActivityType;
  bool _isLoading = false;
  int? userId;
  int? userPermission;
  String? userName;
  int? postUserId;
  String? postUserName;

  // 활동 종류에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _activityType;

  // 활동명에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _activityName;

  // 시작 날짜 선택박스에서 선택된 값
  DateTime? _startDate;

  // 종료 날짜 선택박스에서 선택된 값
  DateTime? _endDate;

  //점수값
  String _activityScore = '';

  // 점수를 입력할 수 있는 박스에서 입력된 값
  int? _acceptedScore;
  int? _subscore;
  int? _inputscore;
  int? wasUploadedacceptedScore;
  // 신청 상태에 대한 드롭다운형식의 콤보박스에서 선택된 값
  String? _applicationStatus;
  String? wasUploadedpass;
  TextEditingController _contentController = TextEditingController();

  // 반려 사유를 입력할 수 있는 텍스트 입력박스에서 입력된 값
  TextEditingController _reasonController = TextEditingController();




  //파일관련
  dynamic? uploadedFileData; //db에서 가져온 파일정보
  String? uploadedFilePath;
  String? uploadedFileName;


  int wasUploadedFile = 0; //업로드된 파일이 있었는가?
  int fileCheck = 0; // 첨부파일이 있는가?


  PlatformFile? selectedFile; //저장소에서 선택한 파일

  String downloadedFilePath = '';

  //작성된 게시글 번호
  // 현재 페이지에는 int postUserId 변수에 할당되어 있음

  //게시글이 정상적으로 업로드 되었는지 체크
  int postUploadCheck = 0;

  //파일이 정상적으로 서버에 업로드 되었는지 체크
  int fileUploadCheck = 0;

  //게시글이 정상적으로 삭제되었는지 체크
  int postDeleteCheck = 0;

  //새로 업로드할 파일의 정보
  Map<String, dynamic> fileInfo={};

  List<String> activityTypes = []; //활동 종류(카테고리)

  Map<String, Map<String, int>> activityNames = {}; //카테고리:{활동명:점수,}


  final _formKey = GlobalKey<FormState>();

  final TextEditingController _scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGsInfo();
    _fetchContent();
    _getUserInfo();
  }
  Future<void> _getWriterInfo() async {

    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/writer?student_id=${widget.post['gsuser_id']}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final writer = jsonDecode(response.body);

      setState(() {
        postUserName = writer['name'];
      });
    } else {
      throw Exception('예외 발생');
    }
  }

  Future<void> _fetchGsInfo() async {
    if (activityTypes.isEmpty) {
      final typeResponse = await http.get(Uri.parse('http://203.247.42.144:443/gScore/getType'));
      if (typeResponse.statusCode == 200) {
        final typeResult = jsonDecode(typeResponse.body);
        for (var typeItem in typeResult) {
          String gsinfoType = typeItem['gsinfo_type'];
          if (!activityTypes.contains(gsinfoType)) {
            activityTypes.add(gsinfoType);
          }
        }
        setState(() {
          activityTypes;
        });
      } else {
        throw Exception('Failed to load types');
      }
    }
  }

  Future<void> _fetchNamesAndScores(String selectedType) async {
    if (!activityNames.containsKey(selectedType)) {
      final encodedType = Uri.encodeComponent(selectedType);
      final infoResponse = await http.get(Uri.parse('http://203.247.42.144:443/gScore/getInfoByType/$encodedType'));
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

  void _fetchContent() {
    setState(() {
      _activityType = widget.post['gspost_category'];

      _activityName = widget.post['gspost_item'];

      postUserId = widget.post['gsuser_id'];

      if (widget.post['gspost_start_date'] != null) {
        _startDate = DateTime.parse(widget.post['gspost_start_date']);
      }

      if (widget.post['gspost_end_date'] != null) {
        _endDate = DateTime.parse(widget.post['gspost_end_date']);
      }

      _activityScore = widget.post['gspost_score'].toString();

      _applicationStatus = widget.post['gspost_pass'].toString();

      if (widget.post['gspost_content'] != null) {
        _contentController.text = widget.post['gspost_content'].toString();
      }



      if (widget.post['gspost_reason'] != null) {
        _reasonController.text = widget.post['gspost_reason'].toString();
      }

      wasUploadedFile = widget.post['gspost_file'];
      fileCheck = widget.post['gspost_file'];
      _getWriterInfo();
      if(wasUploadedFile == 1){
        _getFileInfo();
      }
    });
  }


  Future<void> _getUserInfo() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      return;
    }
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/user'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      userId = user['student_id'];
      userPermission = user['permission'];
      userName = user['name'];

      setState(() {
        userId;
        userPermission;
        userName;
      });
    } else {
      throw Exception('예외 발생');
    }
  }

  Future<void> _getFileInfo() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/fileInfo?postId=${widget.post['gspost_id']}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      uploadedFileData = jsonDecode(response.body);
      uploadedFileName = uploadedFileData['file_original_name'];
      print(uploadedFileName);
      uploadedFilePath = uploadedFileData['file_path'];
      print(uploadedFilePath);

      setState(() {

      });
    } else {
      throw Exception('예외 발생');
    }
  }

  void _selectFile() async {
    var status = await Permission.storage.status;
    debugPrint('저장소 접근권한: ' + status.toString());
    if(await Permission.storage.isDenied) {
      PermissionStatus permissionStatus = await Permission.storage.request();
      debugPrint(permissionStatus.isGranted.toString());
    }
    if (await Permission.storage.isGranted) {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        final File selected = File(file.path!);
        final int maxSize = 5 * 1024 * 1024; // 10MB를 바이트로 표현한 값
        final int fileSize = await selected.length();

        if (fileSize <= maxSize) {
          if (['jpg', 'jpeg', 'png', 'pdf'].contains(file.extension)) {
            setState(() {
              selectedFile = file;
              fileCheck = 1;
            });
          } else {
            showDialog(
              context: context,
              builder: (context) =>
                  AlertDialog(
                    title: Text('파일 확장자 오류'),
                    content: Text('JPG, PNG, PDF 형식의 파일만 지원합니다.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('확인'),
                      ),
                    ],
                  ),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(
                  title: Text('파일 크기 초과'),
                  content: Text('5MB 미만의 파일만 업로드 가능합니다.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('확인'),
                    ),
                  ],
                ),
          );
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: Text('파일 액세스 권한 오류'),
              content: Text('파일을 선택하려면 파일 액세스 권한이 필요합니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('확인'),
                ),
              ],
            ),
      );
    }

  }

  Future<String?> downloadFile() async {
    final response = await http.get(
      Uri.parse('http://203.247.42.144:443/gScore/download?reqPath=${Uri.encodeComponent(uploadedFilePath ?? '')}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      Directory? directory;

      // Android-specific code
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS || Platform.isMacOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isWindows) {
        directory = Directory('C:/Downloads');
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      }

      print(directory);

      if (directory != null) {
        final file = await _createUniqueFileName(directory, uploadedFileName!);
        await file.writeAsBytes(bytes);
        return '파일이 다운로드되었습니다.';
      } else {
        return '저장 폴더 설정 오류';
      }
    } else if (response.statusCode == 404) {
      return '파일이 존재하지 않습니다.';
    } else {
      return '파일 다운로드 중 오류가 발생하였습니다.';
    }
  }

  Future<File> _createUniqueFileName(Directory directory, String originalFileName) async {
    final fileExtension = originalFileName.split('.').last;
    final baseFileName = originalFileName.substring(0, originalFileName.length - fileExtension.length - 1);
    String uniqueFileName = originalFileName;
    int count = 1;

    while (await File('${directory.path}/$uniqueFileName').exists()) {
      uniqueFileName = '$baseFileName($count).$fileExtension';
      count++;
    }
    downloadedFilePath = '${directory.path}/$uniqueFileName';
    return File('${directory.path}/$uniqueFileName');
  }

  Future<void> updateFile() async{
    setState(() => _isLoading = true);
    if(selectedFile!=null){
      if(wasUploadedFile==1){
        await deleteFile();
        await uploadFile();
        if(fileUploadCheck ==1){
          await _uploadfileToDB();
        }
      }
      else{
        await uploadFile();
        if(fileUploadCheck ==1){
          await _uploadfileToDB();
        }
      }

    }else{
      if(wasUploadedFile==1 && uploadedFileName==null){
        await deleteFile();
      }

    }
    setState(() => _isLoading = false); // 버튼 활성화

  }

  Future<void> uploadFile() async {

    if (selectedFile != null) {
      final String fileName = selectedFile!.name;
      final filePath = selectedFile!.path!;

      final maxRetries = 3; // 최대 재시도 횟수
      var retryCount = 0; // 현재 재시도 횟수

      // Timeout values
      final connectTimeout = 60000; // 60 seconds
      final receiveTimeout = 30000; // 30 seconds

      while (retryCount < maxRetries) {
        try {
          var formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(filePath, filename: fileName),
            'gspostid': widget.post['gspost_id'].toString(),
          });

          // Set timeout values for this Dio instance
          var dio = Dio(
            BaseOptions(
              connectTimeout: connectTimeout,
              receiveTimeout: receiveTimeout,
              headers: {'Connection': 'keep-alive'},
            ),
          );

          var response = await dio.post(
            'http://203.247.42.144:443/gScore/upload',
            data: formData,
          );

          print(response.statusCode);

          if (response.statusCode == 201) {
            print("파일 등록 성공");

            var file = response.data['file'];

            fileInfo = {
              'post_id': widget.post['gspost_id'],
              'file_name': file['filename'],
              'file_original_name': file['originalname'],
              'file_size': file['size'],
              'file_path': file['path'],
            };
            fileUploadCheck = 1;

            print(fileInfo);
            return; // 성공적으로 요청을 보냈으면 메서드를 종료
          } else {
            print(response.statusCode);
            print("파일 등록 실패");
          }
        } catch (error) {
          print('등록 네트워크 연결 오류: $error');
        }

        retryCount++;
        await Future.delayed(Duration(seconds: 1)); // 1초 후에 재시도
      }

      print('재시도 횟수 초과');
    }
  }

  Future<void> _uploadfileToDB() async {
    final maxRetries = 4; // 최대 재시도 횟수
    var retryCount = 0; // 현재 재시도 횟수

    while (retryCount < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse('http://203.247.42.144:443/gScore/fileToDB'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(fileInfo),
        );

        if (response.statusCode == 201) {
          print('DB저장 완료');
          return; // 성공적으로 요청을 보냈으면 메서드를 종료
        } else {
          print(response.statusCode);
          print('DB 에러');
        }
      } catch (error) {
        print('db 네트워크 연결 오류: $error');
      }

      retryCount++;
      await Future.delayed(Duration(seconds: 1)); // 1초 후에 재시도
    }

    print('재시도 횟수 초과'); // 최대 재시도 횟수를 초과하면 에러 메시지 출력
  }

  Future<void> deleteFile() async {
    setState(() => _isLoading = true);
    if(wasUploadedFile==1) {
      final maxRetries = 4; // 최대 재시도 횟수
      var retryCount = 0; // 현재 재시도 횟수
      while (retryCount < maxRetries) {
        try {
          final response = await http.delete(
            Uri.parse(
                'http://203.247.42.144:443/gScore/deleteFile?reqPath=${Uri
                    .encodeComponent(uploadedFilePath ?? '')}'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
          );
          setState(() => _isLoading = false); // 버튼 활성화
          if (response.statusCode == 200) {
            print('파일 삭제 성공');
            return; // 성공적으로 요청을 보냈으면 메서드를 종료
          } else {
            print(response.statusCode);
            print('파일 삭제 실패');
          }
        } catch (error) {
          print('삭제 네트워크 연결 오류: $error');
        }

        retryCount++;
        await Future.delayed(Duration(seconds: 1)); // 1초 후에 재시도
      }

      print('재시도 횟수 초과');
    }
  }
  Future<void> updatePost() async {
    setState(() => _isLoading = true);
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('실패: 로그인 정보 없음')));
      });
      return;
    }
    if(_activityName == 'TOPCIT' || _activityName == '50일 이상'){
      print(_acceptedScore);
      _subscore = _inputscore;
    }
    else{
      _subscore = int.tryParse(_activityScore);
    }
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final Map<String, dynamic> postData = {
      'postId': widget.post['gspost_id'],
      'gs_user': widget.post['gsuser_id'],
      'gspost_category': _activityType,
      'gspost_item': _activityName,
      'gspost_content': _contentController.text,
      'gspost_score': (_activityName == 'TOPCIT' || _activityName == '50일 이상') && (_applicationStatus == '대기' || _applicationStatus == '반려')  ? 0 : _subscore,
      'prev_gspost_pass': widget.post['gspost_pass'],
      'gspost_pass': _applicationStatus,
      'gspost_reason': _reasonController.text,
      'gspost_start_date': _startDate != null ? formatter.format(_startDate!) : null,
      'gspost_end_date': _endDate != null ? formatter.format(_endDate!) : null,
      'gspost_file': fileCheck,
      'prev_acceptedScore': widget.post['gspost_accepted_score'],
    };
    final response = await http.post(
      Uri.parse('http://203.247.42.144:443/gScore/update'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': token,
      },
      body: jsonEncode(postData),
    );
    if (response.statusCode == 200) {
      postUploadCheck = 1;
      print("게시글 업데이트 성공");
      print(postData);
    } else {
      postUploadCheck = 0;
      print(response.statusCode);
      print(postData);
      print("게시글 업데이트 실패");
    }
  }

  Future<void> deletePost() async {
    setState(() => _isLoading = true);

    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('실패: 로그인 정보 없음')));
      });
      return;
    }

    final postId = widget.post['gspost_id'];
    final url = Uri.parse('http://203.247.42.144:443/gScore/deletePost?postId=$postId');

    final maxRetries = 4; // 최대 재시도 횟수
    var retryCount = 0; // 현재 재시도 횟수
    while (retryCount < maxRetries) {
      try {
        final response = await http.delete(
          url,
          headers: <String, String>{
            'Authorization': token,
          },
        );
        setState(() => _isLoading = false); // 버튼 활성화
        if (response.statusCode == 200) {
          postDeleteCheck = 1;
          print("게시글 삭제 성공");
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 삭제 실패: 서버 오류')));
          print("게시글 삭제 실패");
          print(response.statusCode);
        }
      } catch (error) {
        print('삭제 네트워크 연결 오류: $error');
      }

      retryCount++;
      await Future.delayed(Duration(seconds: 1)); // 1초 후에 재시도
    }

    print('재시도 횟수 초과');
  }
  //활동종류 드롭박스 눌렀을시 활동명을 초기화 해줘야 충돌이 안남
  void _onActivityTypeChanged(String? newValue) {
    setState(() {
      _activityType = newValue;
      _activityName = null;
      _scoreController.text = '';
      _activityScore = '';
    });

    if (newValue != null) {
      _fetchNamesAndScores(newValue);
    }
  }


  void _onActivityNameChanged(String? newValue) {
    setState(() {
      _activityName = newValue;
      _scoreController.text =
          activityNames[_activityType]?[_activityName]?.toString() ?? '';
      if(_activityName != '50일 이상' || _activityName !='TOPCIT') {
        _activityScore =
            activityNames[_activityType]?[_activityName]?.toString() ?? '';
      }
      else{
        _activityScore = _subscore.toString();
      }
    });
  }

  void deletePostConfirmation() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("게시물 삭제"),
          content: Text("진짜 삭제하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // "Yes" 버튼 클릭 시 true 반환
              },
              child: Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // "No" 버튼 클릭 시 false 반환
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
    if (result == true) {
      if(wasUploadedFile == 1){
        await deleteFile();
      }
      await deletePost(); // 게시물 삭제 함수 호출
    }
    if(postDeleteCheck ==1){
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => GScoreForm()))
          .then((value) {
        setState(() {});
      });
    }
  }

  void _subscore_function(String value){
    if (value.isNotEmpty &&
        _activityName == 'TOPCIT' ||
        _activityName == '50일 이상') {
      _subscore = int.parse(value) * 2;
      if (_activityName == 'TOPCIT' &&
          (_subscore ?? 0) > 1000) {
        _subscore = 1000;
      }
      else if (_activityType == '인턴쉽' &&
          (_subscore ?? 0) > 300) {
        _subscore = 300;
      }
      else if (_activityType == '해외 연수' &&
          (_subscore ?? 0) > 200) {
        _subscore = 200;
      }
      if(_acceptedScore != null) {
        _activityScore = _subscore.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '신청글 조회/수정',
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
          key: _formKey,
          child: Center(
            child: ListView(
              children: <Widget>[
                Row(
                  children: [
                    if (userPermission == 2 || userPermission == 3)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('학번: $postUserId'),
                            ),
                          ),
                        ),
                      ),
                    if (userPermission == 2 || userPermission == 3)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('이름: $postUserName'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동 종류에 대한 드롭다운형식의 콤보박스
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '활동 종류',
                      border: OutlineInputBorder(),
                    ),
                    value:
                    _applicationStatus == '승인' || _applicationStatus == '반려'
                        ? _activityType
                        : _selectedActivityType ?? _activityType,
                    onChanged:
                    (userPermission == 2) || (_applicationStatus == '승인' || _applicationStatus == '반려') || (userPermission == 3)
                        ? null
                        : _onActivityTypeChanged,
                    items: activityTypes
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                        .toList(),
                  ),
                ), //padding1
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  // 활동명에 대한 드롭다운형식의 콤보박스
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '활동명',
                      border: OutlineInputBorder(),
                    ),
                    value: _activityName,
                    onChanged:
                    (userPermission == 2) || (_applicationStatus == '승인' || _applicationStatus == '반려')
                        ? null
                        : _onActivityNameChanged,
                    items:
                    _applicationStatus == '승인' || _applicationStatus == '반려'
                        ? null
                        : activityNames[_activityType]
                        ?.entries
                        .map<DropdownMenuItem<String>>(
                            (MapEntry<String, int> entry) =>
                            DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.key),
                            ))
                        .toList(),
                    // null일 경우에 대한 처리
                    disabledHint:
                    Text(_activityName ?? ''), // 비활성화 된 상태에서 선택된 값을 보여줌
                  ),
                ), //padding2

                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: _applicationStatus == '승인' ||
                              _applicationStatus == '반려',
                          decoration: const InputDecoration(
                            labelText: '시작 날짜',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.date_range),
                          ),
                          onTap: _applicationStatus == '승인' ||
                              _applicationStatus == '반려'
                              ? null
                              : () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            setState(() {
                              _startDate = selectedDate;
                            });
                          },
                          controller: TextEditingController(
                            text: _startDate != null
                                ? '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'
                                : null,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: _applicationStatus == '승인' ||
                              _applicationStatus == '반려',
                          decoration: const InputDecoration(
                            labelText: '종료 날짜',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.date_range),
                          ),
                          onTap: _applicationStatus == '승인' ||
                              _applicationStatus == '반려'
                              ? null
                              : () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            setState(() {
                              _endDate = selectedDate;
                            });
                          },
                          controller: TextEditingController(
                            text: _endDate != null
                                ? '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}'
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ), //padding3
                // 점수 출력박스와 입력박스
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: '점수',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: _subscore_function,
                          controller: TextEditingController(
                            text: _activityScore != null ? _activityScore : activityNames[_activityType]?[_activityName]?.toString() ?? '',
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _activityName == 'TOPCIT' || _activityName == '50일 이상'
                            ? TextFormField(
                          enabled: userPermission == 2,
                          readOnly: widget.post['gspost_accepted_score'] == null,
                          initialValue: widget.post['gspost_accepted_score']?.toString() ?? '',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: const InputDecoration(
                            labelText: '승인 점수',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _inputscore = int.tryParse(value);
                            });
                          },
                        )
                            : TextFormField(
                          enabled: false,
                          initialValue: widget.post['gspost_accepted_score']?.toString() ?? '',
                          decoration: const InputDecoration(
                            labelText: '승인 점수',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                    padding: const EdgeInsets.all(8.0),
                    // 활동 종류에 대한 드롭다운형식의 콤보박스
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '신청 상태',
                        border: OutlineInputBorder(),
                      ),
                      value: _applicationStatus,
                      onChanged: (userPermission == 2 && _activityType != '관리자승인')
                          ? (value) {
                        setState(() {
                          _applicationStatus = value ?? '';
                          if (_applicationStatus == '대기' || _applicationStatus == '반려') {
                            _acceptedScore = 0;
                          }
                        });
                      }
                          : null,

                      items: [
                        DropdownMenuItem(value: '대기', child: Text('대기')),
                        DropdownMenuItem(value: '승인', child: Text('승인')),
                        DropdownMenuItem(value: '반려', child: Text('반려')),
                      ],
                    )),

                //비고란
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: _applicationStatus == '승인' ||
                        _applicationStatus == '반려' || userPermission == 3,
                    decoration: const InputDecoration(
                      labelText: '비고',
                      border: OutlineInputBorder(),
                    ),
                    controller: _contentController,
                  ),
                ),

                // 신청 상태에 대한 드롭다운형식의 콤보박스

                // 반려 사유 입력박스
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    // 활동 종류에 대한 드롭다운형식의 콤보박스
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '반려 사유',
                        border: OutlineInputBorder(),
                      ),
                      enabled: userPermission == 2,
                      controller: _reasonController,
                    )),
                SizedBox(height: 8.0),
                // 첨부파일 업로드박스
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Material(
                    elevation: 5.0, //그림자효과
                    borderRadius: BorderRadius.circular(30.0), //둥근효과
                    color: const Color(0xffC1D3FF),
                    child: MaterialButton(
                      onPressed: () {
                        if(uploadedFileName!=null){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글당 하나의 파일만 업로드 가능합니다.')));
                        }else{
                          _selectFile(); // 파일 선택 수행}
                        }
                      },
                      child: const Text(
                        "첨부파일 업로드",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 활동 종류에 대한 드롭다운형식의 콤보박스
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      labelText: '첨부 파일',
                      labelStyle: TextStyle(
                        fontSize: 16.0,
                      ),
                      suffix: selectedFile != null
                          ? IconButton(
                        onPressed: () {
                          setState(() {
                            selectedFile = null;
                          });
                          // 버튼이 눌렸을 때 수행할 동작
                        },
                        icon: Icon(
                          Icons.delete,
                          color: Colors.grey,
                        ),
                      )
                          : null,
                    ),
                    readOnly: true,
                    controller: TextEditingController(text: '${selectedFile?.name ?? ''}',),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      labelText: '업로드된 파일',
                      labelStyle: TextStyle(
                        fontSize: 16.0,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (uploadedFileName != null)
                            IconButton(
                              onPressed: ()async {
                                final String? downResult = await downloadFile();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(downResult ?? '')));
                                if((Platform.isIOS || Platform.isMacOS) && downResult! == '파일이 다운로드되었습니다.'){
                                  Share.shareFiles([downloadedFilePath]);
                                }
                              },
                              icon: Icon(
                                Icons.file_download,
                                color: Colors.grey,
                              ),
                            ),
                          if (uploadedFileName!=null)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  uploadedFileName = null;
                                  fileCheck = 0;

                                });
                              },
                              icon: Icon(
                                Icons.delete,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    readOnly: true,
                    controller: TextEditingController(text: uploadedFileName ?? ''),

                  ),
                ),

                const SizedBox(height: 8.0),

                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                          elevation: 5.0, //그림자효과
                          borderRadius: BorderRadius.circular(30.0), //둥근효과
                          color: ((userPermission == 2 || _applicationStatus == '대기' || _applicationStatus == '반려') && userPermission != 3)
                              ? const Color(0xffC1D3FF)
                              : const Color(0xff808080),
                          child: MaterialButton(
                            onPressed: ((userPermission == 2 || _applicationStatus == '대기' || _applicationStatus == '반려' || _isLoading) && userPermission !=3) ? () {
                              deletePostConfirmation();
                            } : null,
                            child: _isLoading ? CircularProgressIndicator() :Text(
                              "삭제하기",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 5.0, //그림자효과
                        borderRadius: BorderRadius.circular(30.0), //둥근효과
                        color: ((userPermission == 2 || _applicationStatus == '대기') && userPermission != 3)
                            ? const Color(0xffC1D3FF)
                            : const Color(0xff808080),
                        child: MaterialButton(
                          onPressed: ((userPermission == 2 || _applicationStatus == '대기'|| _isLoading) && userPermission !=3)
                              ? () async{
                            await updatePost();
                            if(postUploadCheck == 1){
                              setState(() => _isLoading = true);
                              await updateFile();
                              setState(() => _isLoading = false);
                            }
                            if(postUploadCheck ==1){
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => GScoreForm()))
                                  .then((value) {
                                setState(() {});
                              });
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 수정 실패: 서버 오류')));
                            }
                            //수정 api

                          }
                              : null,
                          child: _isLoading ? CircularProgressIndicator() :Text(
                            "수정하기",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        elevation: 5.0, //그림자효과
                        borderRadius: BorderRadius.circular(30.0), //둥근효과
                        color: const Color(0xffC1D3FF),
                        child: MaterialButton(
                          onPressed: () {

                            Navigator.pop(context);
                          },
                          child: const Text(
                            "목록으로",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}