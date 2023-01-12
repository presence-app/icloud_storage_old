// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';
export 'package:path_provider_platform_interface/path_provider_platform_interface.dart'
    show StorageDirectory;

void main() {
  runApp(const MyApp());
}

const containerId = 'iCloud.com.presence.app';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String status = '';




  void downloadfile() async {
    final tempDir = await getTemporaryDirectory();
    String filePath = '${tempDir.path}/image.jpg';
    final dio = Dio();
    print("Fetching a sample file from the web... please wait.");
    Response response = await dio.download(
      //  64KB image - use this link to test with small filesize
        //'https://res.cloudinary.com/dornu6mmy/image/upload/v1637745528/POSTS/l9flihokyfchdjauhgkz.jpg',
        // 2.1MB image - use this link to test with medium filesize
           'https://images.unsplash.com/flagged/photo-1568164017397-00f2cec55c97?ixlib=rb-4.0.3&q=80&fm=jpg&crop=entropy&cs=tinysrgb',
        // 21MB pic
        //  'https://images.pexels.com/photos/1168742/pexels-photo-1168742.jpeg',
        filePath);
    if (response.statusCode == 200){
      print("File fetched from web successfully: ${File(filePath).lengthSync()} bytes");
    } else{
      print("Couldn't fetch file from web");
    }
  }

/*
  void uploadToiCloud() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await ICloudStorage.upload(
        containerId: containerId,
        filePath: '${tempDir.path}/image.jpg',
        onProgress: (stream) {
          stream.listen(
                (progress) => print('Upload File Progress: $progress'),
            onDone: () {
              print('Upload File Done');
              // to better check download from iCloud, we delete File
              // from local device soon after it has been uploaded
              deleteFileLocally();
            },
            onError: (err) => print('Upload File Error: $err'),
            cancelOnError: true,
          );
        },
      );
    } catch (err) {
      handleError(err);
    }
  }
*/

  void uploadToiCloud() async {
    var isIOS16 = true;
    var fake_progress = 0.0;
    final destinationPath = await getTemporaryDirectory();

    await ICloudStorage.upload(
      containerId: containerId,
      filePath: '${destinationPath.path}/image.jpg',
      onProgress: (stream) {
        stream.listen(
              (progress) {
                // If ios16 we use a fake progress to workaround upload progress bug
                if (isIOS16 == false){
                print('Upload File Progress: $progress');
                }
                else {
                print('Upload File Progress: $fake_progress');
                fake_progress = fake_progress + 25.0;
                }
              },
          onDone: () {
            print('Upload File Progress: 100.0');
            print('Upload File Done');
            // to better check download from iCloud, we delete File
            // from local device soon after it has been uploaded
            deleteFileLocally();
          },
          onError: (err) => print('Upload File Error: $err'),
          cancelOnError: true,
        );
      },
    );

  }


  Future<void> downloadiCloudFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      await ICloudStorage.download(
        containerId: containerId,
        relativePath: 'image.jpg',
        destinationFilePath: '${tempDir.path}/image.jpg',
        onProgress: (stream) {
          stream.listen(
                (progress) => print('Download File Progress: $progress'),
            onDone: () {
              print('Download File Done');
            },
            onError: (err) => print('Download File Error: $err'),
            cancelOnError: false,
          );
        },
      );
    } catch (err) {
      handleError(err);
    }
  }

  Future<void> listiCloudFiles() async {
    final fileList = await ICloudStorage.gather(
      containerId: containerId,
      onUpdate: (stream) {
        stream.listen((updatedFileList) {
          print('FILE UPDATED:');
          updatedFileList.forEach((file) => print('-- ${file.relativePath}: ${file.sizeInBytes} bytes'));
        });
      },
    );
    print('LIST FILES');
    fileList.forEach((file) => print('-- ${file.relativePath}: ${file.sizeInBytes} bytes'));
  }


  Future<void> deleteFile() async {
    await ICloudStorage.delete(
        containerId: containerId,
        relativePath: 'image.jpg'
    );
  }

  Future<void> deleteFileLocally() async {
    // delete file from local device
    final tempDir = await getTemporaryDirectory();
    try {
      await File('${tempDir.path}/image.jpg').delete();
      print('File Deleted from local storage');
    } catch (err) {
      handleError(err);
    }
  }


  Future<void> checkFile() async {
    final tempDir = await getTemporaryDirectory();
    String filepath = "${tempDir.path}/image.jpg";
    print(await File(filepath).exists());
    if (await File(filepath).exists()==true){
      print('FILE Exists: $filepath: ${File(filepath).lengthSync()} bytes');
    } else{
      print('FILE $filepath doesnt Exists');
    }
  }


  void handleError(dynamic err) {
    if (err is PlatformException) {
      if (err.code == PlatformExceptionCode.iCloudConnectionOrPermission) {
        print(
            'Platform Exception: iCloud container ID is not valid, or user is not signed in for iCloud, or user denied iCloud permission for this app');
      } else {
        print('Platform Exception: ${err.message}; Details: ${err.details}');
      }
    } else {
      print(err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: downloadfile,
                child: const Text("1. Fetch 'image' file from Web")),
            ElevatedButton(
                onPressed: uploadToiCloud,
                child: const Text("2. Upload 'image' file to icloud")),
            ElevatedButton(
                onPressed: downloadiCloudFile,
                child: const Text("3. Download 'image' file from icloud")),
            ElevatedButton(
                onPressed: listiCloudFiles,
                child: const Text("4. List all files from icloud")),
            ElevatedButton(
                onPressed: deleteFile,
                child: const Text("5. Delete 'image' file from icloud")),
            ElevatedButton(
                onPressed: deleteFileLocally,
                child: const Text("6. Delete 'image' file locally")),
            ElevatedButton(
                onPressed: checkFile,
                child: const Text("7. Check if 'image' file exists locally")),
          ],
        ),
      ),
    );
  }
}

