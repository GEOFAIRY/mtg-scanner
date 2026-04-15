import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

typedef ChildBuilder = Widget Function(BuildContext);

class CameraPermissionGate extends StatefulWidget {
  const CameraPermissionGate({required this.child, super.key});
  final ChildBuilder child;
  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate> {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _request();
  }

  Future<void> _request() async {
    final s = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (s.isGranted) return widget.child(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Camera access is required to scan cards. Grant it in system settings.',
                  textAlign: TextAlign.center),
              SizedBox(height: 16),
              _OpenSettingsButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenSettingsButton extends StatelessWidget {
  const _OpenSettingsButton();

  @override
  Widget build(BuildContext context) {
    return const FilledButton(
      onPressed: openAppSettings,
      child: Text('Open settings'),
    );
  }
}

