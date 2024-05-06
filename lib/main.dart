import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String filepath = "";
  String UploadURL = "";
  int ofset = 0;

  // SharedPreferences? prefs;

  @override
  initState() {
    super.initState();
   // SharedPreferences.getInstance().then((value) {
      // prefs = value;

      // if ((prefs!.getInt("sent") != 0) &&
      //     (prefs!.getString("filePath") != null) &&
      //     (prefs!.getString("uploadLink") != null)) {
     // resumeUpload(prefs!.getString("filePath")!,
       //   prefs!.getString("uploadLink")!, prefs!.getInt("sent")!);
      // }
   // });
  }

  Future<void> _incrementCounter() async {
    // setState(() {
    //   // This call to setState tells the Flutter framework that something has
    //   // changed in this State, which causes it to rerun the build method below
    //   // so that the display can reflect the updated values. If we changed
    //   // _counter without calling setState(), then the build method would not be
    //   // called again, and so nothing would appear to happen.
    //   _counter++;
    // });

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      filepath = result.files.single.path!;
      File file = File(result.files.single.path!);
      //    prefs!.setString("filePath", result.files.single.path!);
      uploadVideo(file, "22", uploadProgressCallback);
    } else {
      // User canceled the picker
    }
  }

  void uploadProgressCallback(int progress) {
    print('Upload progress: $progress%');
  }

  Future<String?> uploadVideo(
    File file,
    String courseID,
    dynamic uploadProgressCallback(int prog),
  ) async {
    try {
      var response = await Dio().post(
        "https://api.vimeo.com/me/videos",
        data: {
          "upload": {
            "approach": "tus",
            "size": "${file.lengthSync()}",
          },
          // "name": "$courseID",
          // "privacy": {
          //   "embed": "private",
          //   "view": "nobody",
          // },
        },
        options: Options(
          headers: {
            "Authorization": "bearer 9c0af62a615052377bd51ff954fac6d2",
            "Content-Type": "application/json",
            "Accept": "application/vnd.vimeo.*+json;version=3.4"
          },
        ),
      );
      print("code  " + response.statusCode.toString());
      print(response.data.toString());
      // final Map parsed = json.decode(response.data.toString());
      print("parsed ${response.data["upload"]["upload_link"]}");
      String id = response.data["uri"];

      id = id.substring(8, id.length);
      print(id);
      print(file);
      // prefs!.setString("uploadLink", response.data["upload"]["upload_link"]);
      UploadURL = response.data["upload"]["upload_link"];
      await Dio().patch(
        response.data["upload"]["upload_link"],
        data: Stream.fromIterable(file.readAsBytesSync().map((e) => [e])),
        options: Options(
          headers: {
            "Content-Length": "${file.lengthSync()}",
            "Tus-Resumable": "1.0.0",
            "Upload-Offset": "0",
            "Content-Type": "application/offset+octet-stream",
            "Accept": "application/vnd.vimeo.*+json;version=3.4",
          },
        ),
        onSendProgress: (int sent, int total) {
          final progress = ((sent / total) * 100).floor();
          if (sent == 1000000 && _counter == 0) {
            //_counter++;
            throw Exception("Force Crash $progress $total $sent"
            );
          }
          // if (prefs != null) {
          //   prefs!.setInt("sent", sent);
          // }
          // if (_counter < progress) {
          //   _counter = progress;
          //   uploadProgressCallback(progress);
          // }
          ofset = sent;
        },
        onReceiveProgress: (int sent, int total) {},
      );
      return id;
    } catch (e) {
      print("catE "+e.toString());
      resumeUpload(filepath, UploadURL, ofset);
    }
  }

  resumeUpload(String filePath, String uploadLink, int offSet) async {
    File file = File(filePath);

    try {
      await http.patch(
        Uri(path: uploadLink)
        ,
          headers: {
            "Content-Length": "${file.lengthSync()}",
            "Tus-Resumable": "1.0.0",
            "Upload-Offset": "1000000",
            "Content-Type": "application/offset+octet-stream",
            "Accept": "application/vnd.vimeo.*+json;version=3.4",
          },
        body: file.openRead(1000000, file.lengthSync()),
        // options: Options(
        //   headers: {
        //     "Content-Length": "${file.lengthSync()}",
        //     "Tus-Resumable": "1.0.0",
        //     "Upload-Offset": "1000000",
        //     "Content-Type": "application/offset+octet-stream",
        //     "Accept": "application/vnd.vimeo.*+json;version=3.4",
        //   },
        // ),
        // onSendProgress: (int sent, int total) {
        //   final progress = ((sent / total) * 100).floor();
        //   print("sent total :  $sent $total");
        //   if (_counter <= progress) {
        //     _counter = progress;
        //     uploadProgressCallback(progress);
        //   }
        // },
        // onReceiveProgress: (int rec, int total) {
        // },
      );
      // ).catchError((e){
      //   print("Eeeeeeee1   " + e.toString());
      // });
      //
      // print(res.statusCode);
    } on DioException catch (e) {
      print("Eeeeeeee1   " + e.error.toString());
    } catch (e) {
      print("Eeeeeeee   " + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
