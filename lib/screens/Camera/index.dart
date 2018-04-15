import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ScreenCamera extends StatefulWidget {
  @override
  _ScreenCameraState createState() => new _ScreenCameraState();
}

class _ScreenCameraState extends State<ScreenCamera> {
  CameraController controller;

  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();

    availableCameras().then((_) {
      setState(() {
        cameras = _;
      });
      change();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget columnChildren;

    if (controller == null || !controller.value.initialized) {} else if (controller.value.hasError) {} else {
      columnChildren = new Column(
        children: <Widget>[
          new Expanded(
              child: new AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: new CameraPreview(controller),
          ))
        ],
      );
    }
    return new Scaffold(
        body: columnChildren,
        floatingActionButton: (controller == null)
            ? null
            : new FloatingActionButton.extended(
                onPressed: controller.value.isStarted ? capture : null,
                icon: const Icon(Icons.camera),
                label: new Text("Shot"),
              ));
  }

  int curCam = -1;

  Future<Null> change() async {
    if (controller != null) {
      final CameraController tempController = controller;
      controller = null;
      await tempController?.dispose();
    }
    controller = new CameraController(cameras[(++curCam) % 2], ResolutionPreset.high);
    await controller.initialize();
    setState(() {});
  }

  Future<Null> capture() async {
    if (controller.value.isStarted) {
      final Directory tempDir = await getTemporaryDirectory();
      if (!mounted) {
        return;
      }
      final String tempPath = tempDir.path;
      final String path = '$tempPath/picture${new DateTime.now().millisecondsSinceEpoch}.jpg';
      await controller.capture(path);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, new File(path));
    }
  }
}
