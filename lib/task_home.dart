import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';

class TaskHome extends StatefulWidget {
  const TaskHome({super.key});

  @override
  _TaskHomeState createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  Uint8List? imageBytes;
  Uint8List? logoBytes;
  File? watermarkedImageFile;
  final TextEditingController _textController = TextEditingController();
  String watermarkText = "";
  final TextEditingController _controller = TextEditingController();
  static const List<SocialPlatform> _platforms = SocialPlatform.values;
  String? _mediaPath;

  @override
  void initState() {
    super.initState();
    loadLogo();
  }

  Future<void> loadLogo() async {
    final ByteData logoData = await rootBundle.load('assets/Youm7.png');
    setState(() {
      logoBytes = logoData.buffer.asUint8List();
    });
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageBytes = File(pickedFile.path).readAsBytesSync();
        watermarkedImageFile = null;
      });
    }
  }

  void addWatermark() async {
    if (imageBytes != null && logoBytes != null) {
      File watermarkedImage =
          await addWatermarkToImage(imageBytes!, watermarkText, logoBytes);
      setState(() {
        watermarkedImageFile = watermarkedImage;
        _mediaPath = watermarkedImage.path;
      });
    }
  }

  Future<void> _share(
    SocialPlatform platform, {
    bool isMultipleShare = false,
  }) async {
    final String content = _controller.text;
    if (_mediaPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No watermarked image to share."),
        ),
      );
      return;
    }

    isMultipleShare
        ? await SocialSharingPlus.shareToSocialMediaWithMultipleMedia(
            platform,
            media: [_mediaPath!],
            content: content,
            isOpenBrowser: true,
            onAppNotInstalled: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content:
                      Text('${platform.name.capitalize} is not installed.'),
                ));
            },
          )
        : await SocialSharingPlus.shareToSocialMedia(
            platform,
            content,
            media: _mediaPath,
            isOpenBrowser: true,
            onAppNotInstalled: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content:
                      Text('${platform.name.capitalize} is not installed.'),
                ));
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text("Dream Soft Task"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Pick Image from Gallery"),
              ),
              const SizedBox(height: 20),
              imageBytes != null
                  ? SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: Image.memory(imageBytes!),
                    )
                  : const Text("No image selected"),
              const SizedBox(height: 20),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: "Enter Watermark Text",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    watermarkText = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addWatermark,
                child: const Text("Add Watermark"),
              ),
              const SizedBox(height: 20),
              watermarkedImageFile != null
                  ? SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: Image.file(watermarkedImageFile!),
                    )
                  : const Text("No watermarked image yet"),
              const SizedBox(height: 20),
              ..._platforms.map(
                (SocialPlatform platform) => ElevatedButton(
                  onPressed: () => _share(
                    platform,
                    isMultipleShare: true,
                  ),
                  child: Text('Share to ${platform.name.capitalize}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<File> addWatermarkToImage(
    Uint8List imageBytes, String watermarkText, Uint8List? logoBytes) async {
  img.Image originalImage = img.decodeImage(imageBytes)!;

  int containerHeight = (originalImage.height * 0.1).toInt();

  img.fillRect(
      originalImage,
      0,
      originalImage.height - containerHeight,
      originalImage.width,
      originalImage.height,
      img.getColor(255, 255, 255, 255));

  // Add black watermark text in the white container
  if (watermarkText.isNotEmpty) {
    int textSize = (originalImage.width * 0.05).toInt();
    int x = (originalImage.width - textSize * watermarkText.length ~/ 2) ~/ 2;
    int y = originalImage.height -
        containerHeight +
        (containerHeight - textSize) ~/ 2;

    img.drawString(originalImage, img.arial_48, x, y, watermarkText,
        color: img.getColor(0, 0, 0)); // Black text
  }

  // Add the logo at the top-right corner if available
  if (logoBytes != null) {
    img.Image logo = img.decodeImage(logoBytes)!;
    int logoSize = (originalImage.width * 0.2).toInt();
    logo = img.copyResize(logo, width: logoSize);

    int x = originalImage.width - logo.width - 20;
    int y = 20;

    img.drawImage(originalImage, logo, dstX: x, dstY: y);
  }

  // Encode the final image with watermark
  Uint8List newImageBytes = Uint8List.fromList(img.encodePng(originalImage));

  // Save the watermarked image
  final directory = await getTemporaryDirectory();
  File watermarkedImage = File('${directory.path}/watermarked_image.png');
  await watermarkedImage.writeAsBytes(newImageBytes);

  return watermarkedImage;
}

extension StringExtension on String {
  String get capitalize => "${this[0].toUpperCase()}${substring(1)}";
}
