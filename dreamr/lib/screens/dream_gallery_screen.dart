import 'package:flutter/material.dart';
import 'package:dreamr/models/dream.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/widgets/main_scaffold.dart';
import 'package:dreamr/screens/image_viewer_screen.dart';


class DreamGalleryScreen extends StatefulWidget {
  const DreamGalleryScreen({Key? key}) : super(key: key);

  @override
  State<DreamGalleryScreen> createState() => _DreamGalleryScreenState();
}

class _DreamGalleryScreenState extends State<DreamGalleryScreen> {
  List<Dream> _dreams = [];            // all dreams
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    final dreams = await ApiService.fetchDreams(); // assumes .image_tile and .summary are available
    setState(() {
      _dreams = dreams;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      // title: const Text("Dreamr ✨ Gallery", style: TextStyle(color: Colors.white)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Dreamr ✨ Gallery",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2),
          Text(
            "Your personal AI-powered dream analysis",
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Color(0xFFD1B2FF),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: _dreams.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // adjust for screen size later if needed
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final dream = _dreams[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewerScreen(
                                  dreams: _dreams,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              dream.imageTile ?? '',
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.broken_image, size: 40)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dream.summary ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
