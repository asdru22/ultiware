import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomImagePicker extends StatefulWidget {
  const CustomImagePicker({super.key});

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  List<AssetEntity> _recentPhotos = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.videos,
    ].request();

    if (statuses[Permission.camera]!.isGranted) {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _initCamera(_cameras![0]);
      }
    }

    if (statuses[Permission.photos]!.isGranted ||
        statuses[Permission.photos]!.isLimited) {
      _fetchRecentPhotos();
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initCamera(CameraDescription cameraDescription) async {
    final prevController = _controller;
    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await prevController?.dispose();

    if (mounted) {
      setState(() {
        _controller = newController;
      });
    }

    try {
      await newController.initialize();
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _initCamera(_cameras![_selectedCameraIndex]);
  }

  Future<void> _fetchRecentPhotos() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (paths.isNotEmpty) {
      // Get recent photos from the "Recent" album (usually index 0)
      final List<AssetEntity> entities = await paths[0].getAssetListRange(
        start: 0,
        end: 20,
      );
      if (mounted) {
        setState(() {
          _recentPhotos = entities;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile file = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, {'path': file.path, 'source': 'camera'});
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _selectGalleryImage(AssetEntity entity) async {
    final File? file = await entity.file;
    if (file != null && mounted) {
      Navigator.pop(context, {'path': file.path, 'source': 'gallery'});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CameraPreview(_controller!)),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildRecentPhotosStrip(),
                _buildControls(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPhotosStrip() {
    if (_recentPhotos.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recentPhotos.length,
        itemBuilder: (context, index) {
          final asset = _recentPhotos[index];
          return GestureDetector(
            onTap: () => _selectGalleryImage(asset),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<Uint8List?>(
                future: asset.thumbnailDataWithSize(
                  const ThumbnailSize.square(200),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  }
                  return const ColoredBox(color: Colors.grey);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 32.0,
        left: 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 32,
            ),
          ),
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 4,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleCamera,
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
