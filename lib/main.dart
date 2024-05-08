import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



import 'dart:convert' show base64, utf8;
import 'dart:math' show min;
import 'dart:typed_data' show Uint8List, BytesBuilder;

import 'package:tusc/src/exceptions.dart';
import 'package:tusc/src/cache.dart';
import 'package:tusc/src/tus_upload_state.dart';
import 'package:tusc/src/utils/map_utils.dart';
import 'package:tusc/src/utils/num_utils.dart';
import 'package:cross_file/cross_file.dart' show XFile;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;




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
      //uploadVideo(file, "22", uploadProgressCallback);
      uploadTusc(file,filepath);
    } else {
      // User canceled the picker
    }
  }

  void uploadProgressCallback(int progress) {
    print('Upload progress: $progress%');
  }

  uploadTusc(File file,String path) async {

    var response = await Dio().post(
      "https://api.vimeo.com/me/videos",
      data: {
        "upload": {
          "approach": "tus",
          "size": "${file.lengthSync()}",
        },
      },
      options: Options(
        headers: {
          "Authorization": "bearer 9c0af62a615052377bd51ff954fac6d2",
          "Content-Type": "application/json",
          "Accept": "application/vnd.vimeo.*+json;version=3.4"
        },
      ),
    );

      /// File to be uploaded
      //final file = XFile('/path/to/some/video.mp4');
      final uploadURL = response.data["upload"]["upload_link"];

      /// Create a client
      final tusClient = Tus2Client(
        url: "https://api.vimeo.com/me/videos",

        /// Required
        file: XFile(path),

        /// Required
        chunkSize: 5.MB,

        /// Optional, defaults to 256 KB
        tusVersion: Tus2Client.defaultTusVersion,

        /// Optional, defaults to 1.0.0. Change this only if your tus server uses different version
       // cache: TusPersistentCache('/some/path'),

        /// Optional, defaults to null. See also [TusMemoryCache]
        headers: <String, dynamic>{
          /// Optional, defaults to null. Use it when you need to pass extra headers in request like for authentication
          // HttpHeaders.authorizationHeader:
          // 'bearer 9c0af62a615052377bd51ff954fac6d2'
          "Authorization": "bearer 9c0af62a615052377bd51ff954fac6d2",
      "Content-Type": "application/json",
      "Accept": "application/vnd.vimeo.*+json;version=3.4"
        },
        // metadata: <String, dynamic>{
        //   /// Optional, defaults to null. Use it when you need to pass extra data like file name or any other specific business data
        //   'name': 'my-video'
        // },
        timeout: Duration(minutes: 10),

        /// Optional, defaults to 30 seconds
        httpClient: http.Client(),

        /// Optional, defaults to http.Client(), use it when you need more control over http requests
      );

      /// Starts the upload
      tusClient.startUpload(
        /// count: the amount of data already uploaded
        /// total: the amount of data to be uploaded
        /// response: the http response of the last chunkSize uploaded
          onProgress: (count, total, progress) {
            print('Progress: $count of $total | ${(count / total * 100).toInt()}%');
          },

          /// response: the http response of the last chunkSize uploaded
          onComplete: (response) {
            print('Upload Completed');
            print(tusClient.uploadUrl.toString());
          }, onTimeout: () {
        print('Upload timed out');
      });

      await Future.delayed(const Duration(seconds: 10), () async {
        await tusClient.pauseUpload();
        print(tusClient.state);
        /// Pauses the upload progress
      });

      await Future.delayed(const Duration(seconds: 10), () async {
        await tusClient.cancelUpload();
        print(tusClient.state);
        /// Cancels the upload progress
      });

      await Future.delayed(const Duration(seconds: 10), () async {
        tusClient.resumeUpload();
        print(tusClient.state);
        /// Resumes the upload progress where it left of, and notify to the same callbacks used in the startUpload(...)
      });
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
      await Dio(BaseOptions(
        connectTimeout: Duration(minutes: 5),
        receiveTimeout: Duration(minutes: 5),
        sendTimeout: Duration(minutes: 5),

      )).patch(
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
            // throw Exception("Force Crash $progress $total $sent"
            // );
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
     // resumeUpload(filepath, UploadURL, ofset);
    }
  }

  resumeUpload(String filePath, String uploadLink, int offSet) async {
    File file = File(filePath);


    print("ssss"+file.openRead(1000000, file.lengthSync()).length.toString());

    try {
      await Dio(BaseOptions(
        connectTimeout: Duration(minutes: 5),
        receiveTimeout: Duration(minutes: 5),
        sendTimeout: Duration(minutes: 5),

      )).patch(
        uploadLink,
        data: file.openRead(1000000, file.lengthSync()),
        options: Options(
          headers: {
            "Content-Length": "${file.lengthSync()}",
            "Tus-Resumable": "1.0.0",
            "Upload-Offset": "1000000",
            "Content-Type": "application/offset+octet-stream",
            "Accept": "application/vnd.vimeo.*+json;version=3.4",
          },
        ),
        onSendProgress: (int sent, int total) {
          final progress = ((sent / total) * 100).floor();
          print("sent total :  $sent $total");
          if (_counter <= progress) {
            _counter = progress;
            uploadProgressCallback(progress);
          }
        },
        onReceiveProgress: (int rec, int total) {
        },
      );
    } on DioException catch (e) {
      print("error1   " + e.error.toString());
    } catch (e) {
      print("error2   " + e.toString());
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



typedef ProgressCallback = void Function(
    int count, int total, http.Response? response);

/// Callback to listen when upload finishes
typedef CompleteCallback = void Function(http.Response response);

/// This is a client for the tus(https://tus.io) protocol.
class Tus2Client {
  /// Version of the tus protocol used by the client. The remote server needs to
  /// support this version, too.
  static const defaultTusVersion = '1.0.0';
  static const contentTypeOffsetOctetStream = 'application/offset+octet-stream';

  static const tusResumableHeader = 'tus-resumable';
  static const uploadMetadataHeader = 'upload-metadata';
  static const uploadOffsetHeader = 'upload-offset';
  static const uploadLengthHeader = 'upload-length';

  /// The tus server URL
  final String url;

  /// The file to upload
  final XFile file;

  /// The tus protocol version you want to use
  /// Default value: 1.0.0
  final String tusVersion;

  /// Storage used to save and retrieve upload URLs by its fingerprint.
  /// This is required if you need to pause/resume uploads.
  final TusCache? cache;

  /// Metadata for specific upload server
  final Map<String, dynamic>? metadata;

  /// Any additional headers
  final Map<String, String> headers;

  /// The size in bytes when uploading the file in chunks
  /// Default value: 256 KB
  final int chunkSize;

  /// Timeout duration for tus server requests
  /// Default value: 30 seconds
  final Duration timeout;

  /// Set this if you need to use a custom http client
  final http.Client httpClient;

  int _fileSize = 0;
  late final String _fingerprint;
  late final String _uploadMetadata;
  Uri _uploadURI = Uri();
  int _offset = 0;
  TusUploadState _state;
  Future? _uploadFuture;
  ProgressCallback? _onProgress;
  CompleteCallback? _onComplete;
  Function()? _onTimeout;
  String? _errorMessage;

  Tus2Client({
    required this.url,
    required this.file,
    int? chunkSize,
    this.tusVersion = defaultTusVersion,
    this.cache,
    Map<String, dynamic>? headers,
    this.metadata,
    Duration? timeout,
    http.Client? httpClient,
  })  : chunkSize = chunkSize ?? 256.KB,
        headers = headers?.parseToMapString ?? {},
        timeout = timeout ?? const Duration(seconds: 30),
        httpClient = httpClient ?? http.Client(),
        _state = TusUploadState.notStarted {
    _fingerprint = generateFingerprint();
    _uploadMetadata = generateMetadata();
  }

  /// Get the upload state
  TusUploadState get state => _state;

  /// Get the error message in case of any error
  String? get errorMessage => _errorMessage;

  /// Whether the client supports resuming
  bool get resumingEnabled => cache != null;

  /// The URI on the server for the file
  String get uploadUrl => _uploadURI.toString();

  /// The fingerprint of the file being uploaded
  String get fingerprint => _fingerprint;

  /// The uploadMetadataHeaderKey header sent to server
  String get uploadMetadata => _uploadMetadata;

  /// Create a new [startUpload] throwing [ProtocolException] on server error
  Future<void> _createUpload() async {
    _fileSize = await file.length();

    final createHeaders = {
      ...headers,
      tusResumableHeader: tusVersion,
      uploadMetadataHeader: _uploadMetadata,
      uploadLengthHeader: '$_fileSize',
      "Content-Type" : "application/json",
    };
    String rawBody = '''
    {
      "upload": {
        "approach": "tus",
        "size": "$_fileSize"
      }
    }
  ''';
    final response =
    await httpClient.post(Uri.parse(url), headers: createHeaders,body: rawBody);

    if (!(response.statusCode >= 200 && response.statusCode < 300)) {
      _state = TusUploadState.error;
      throw ProtocolException(
          _errorMessage =
          'Unexpected status code11 (${response.statusCode}) while creating upload',
          response);
    }

    // String locationURL =
    //     response.headers[HttpHeaders.locationHeader]?.toString() ?? '';
    String locationURL = jsonDecode(response.body)["upload"]["upload_link"];
    if (locationURL.isEmpty) {
      _state = TusUploadState.error;
      throw ProtocolException(
          _errorMessage = 'Missing upload URL in response for creating upload',
          response);
    }

    _uploadURI = _parseToURI(locationURL);
    cache?.set(_fingerprint, _uploadURI.toString());
    _state = TusUploadState.created;
  }

  /// Check if it's possible to resume an already started upload
  Future<bool> canResume() async {
    if (!resumingEnabled) return false;
    _fileSize = await file.length();

    _uploadURI = Uri.parse(await cache?.get(_fingerprint) ?? '');

    return _uploadURI.toString().isNotEmpty;
  }

  Future<void> _upload() async {
    _errorMessage = null;
    if (!await canResume()) {
      await _createUpload();
    }

    // Get offset from server
    _offset = await _getOffset();

    http.Response? response;

    final uploadHeaders = {
      ...headers,
      tusResumableHeader: tusVersion,
      uploadOffsetHeader: '$_offset',
      HttpHeaders.contentTypeHeader: contentTypeOffsetOctetStream
    };

    // Start upload
    _state = TusUploadState.uploading;
    while ((_state != TusUploadState.paused &&
        _state != TusUploadState.completed &&
        _state != TusUploadState.cancelled) &&
        _offset < _fileSize) {
      _state = TusUploadState.uploading;
      // Update upload progress
      _onProgress?.call(_offset, _fileSize, response);

      uploadHeaders[uploadOffsetHeader] = '$_offset';

      _uploadFuture = httpClient.patch(
        _uploadURI,
        headers: uploadHeaders,
        body: await _getData(),
      );
      response = await _uploadFuture?.timeout(timeout, onTimeout: () {
        _onTimeout?.call();
        _state = TusUploadState.error;
        return http.Response('', HttpStatus.requestTimeout,
            reasonPhrase: _errorMessage = 'Request timeout');
      });
      _uploadFuture = null;

      // Check if correctly uploaded
      if (!(response!.statusCode >= 200 && response.statusCode < 300)) {
        _state = TusUploadState.error;
        throw ProtocolException(
            _errorMessage =
            'Unexpected status code (${response.statusCode}) while uploading chunk',
            response);
      }

      int? serverOffset = _parseOffset(response.headers[uploadOffsetHeader]);
      if (serverOffset == null) {
        _state = TusUploadState.error;
        throw ProtocolException(
            _errorMessage =
            'Response to PATCH request contains no or invalid Upload-Offset header',
            response);
      }
      if (_offset != serverOffset) {
        _state = TusUploadState.error;
        throw ProtocolException(
            _errorMessage =
            'Response contains different Upload-Offset value ($serverOffset) than expected ($_offset)',
            response);
      }
    }

    // Update upload progress
    _onProgress?.call(_offset, _fileSize, response);

    if (_offset == _fileSize) {
      // Upload completed
      _state = TusUploadState.completed;
      cache?.remove(_fingerprint);
      _onComplete?.call(response!);
    }
  }

  /// Starts or resumes an upload in chunks of [chunkSize].
  /// Throws [ProtocolException] on server error.
  Future<void> startUpload({
    /// Callback to notify about the upload progress. It provides [count] which
    /// is the amount of data already uploaded, [total] the amount of data to be
    /// uploaded and [response] which is the http response of the last
    /// [chunkSize] uploaded.
    ProgressCallback? onProgress,

    /// Callback to notify the upload has completed. It provides a [response]
    /// which is the http response of the last [chunkSize] uploaded.
    CompleteCallback? onComplete,

    /// Callback to notify the upload timed out according to the [timeout]
    /// property specified in the [TusClient] constructor which by default is
    /// 30 seconds
    Function()? onTimeout,
  }) async {
    _onProgress = onProgress;
    _onComplete = onComplete;
    _onTimeout = onTimeout;
    _state = TusUploadState.uploading;
    return _upload();
  }

  /// Resumes an upload where it left of. This function calls [upload()]
  /// using the same callbacks used last time [upload()] was called.
  /// Throws [ProtocolException] on server error
  Future<void> resumeUpload() => startUpload(
    onProgress: _onProgress,
    onComplete: _onComplete,
    onTimeout: _onTimeout,
  );

  /// Pause the current upload
  Future? pauseUpload() {
    return _uploadFuture?.timeout(Duration.zero, onTimeout: () {
      _state = TusUploadState.paused;
      return http.Response('', 200, reasonPhrase: 'Upload request paused');
    });
  }

  /// Cancel the current upload
  Future? cancelUpload() {
    return _uploadFuture?.timeout(Duration.zero, onTimeout: () {
      _state = TusUploadState.cancelled;
      cache?.remove(_fingerprint);
      return http.Response('', 200, reasonPhrase: 'Upload request cancelled');
    });
  }

  /// Override this method to customize creating file fingerprint
  String generateFingerprint() {
    return file.path.replaceAll(RegExp(r'\W+'), '.');
  }

  /// Override this to customize the header 'Upload-Metadata'
  String generateMetadata() {
    final meta = metadata?.parseToMapString ?? {};

    if (!meta.containsKey('filename')) {
      meta['filename'] = p.basename(file.path);
    }

    return meta.entries
        .map((entry) =>
    '${entry.key} ${base64.encode(utf8.encode(entry.value))}')
        .join(',');
  }

  /// Get offset from server throwing [ProtocolException] on error
  Future<int> _getOffset() async {
    final offsetHeaders = {
      ...headers,
      tusResumableHeader: tusVersion,
    };
    final response = await httpClient.head(_uploadURI, headers: offsetHeaders);

    if (!(response.statusCode >= 200 && response.statusCode < 300)) {
      _state = TusUploadState.error;
      throw ProtocolException(
          _errorMessage =
          'Unexpected status code (${response.statusCode}) while resuming upload',
          response);
    }

    int? serverOffset = _parseOffset(response.headers[uploadOffsetHeader]);
    if (serverOffset == null) {
      _state = TusUploadState.error;
      throw ProtocolException(
          _errorMessage =
          'Missing upload offset in response for resuming upload',
          response);
    }
    return serverOffset;
  }

  /// Get data from file to upload
  Future<Uint8List> _getData() async {
    int start = _offset;
    int end = _offset + chunkSize;
    end = end > _fileSize ? _fileSize : end;

    final result = BytesBuilder();
    await for (final chunk in file.openRead(start, end)) {
      result.add(chunk);
    }

    final bytesRead = min(chunkSize, result.length);
    _offset = _offset + bytesRead;

    return result.takeBytes();
  }

  int? _parseOffset(String? offset) {
    if (offset == null || offset.isEmpty) return null;
    if (offset.contains(',')) {
      offset = offset.substring(0, offset.indexOf(','));
    }
    return int.tryParse(offset);
  }

  Uri _parseToURI(String locationURL) {
    if (locationURL.contains(',')) {
      locationURL = locationURL.substring(0, locationURL.indexOf(','));
    }
    Uri uploadURI = Uri.parse(locationURL);
    Uri baseURI = Uri.parse(url);
    if (uploadURI.host.isEmpty) {
      uploadURI = uploadURI.replace(host: baseURI.host, port: baseURI.port);
    }
    if (uploadURI.scheme.isEmpty) {
      uploadURI = uploadURI.replace(scheme: baseURI.scheme);
    }
    return uploadURI;
  }
}
