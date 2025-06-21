import 'package:flutter/material.dart';
import 'package:dreamr/models/dream.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:dreamr/theme/colors.dart';


class DreamJournalWidget extends StatefulWidget {
  const DreamJournalWidget({Key? key}) : super(key: key);

  @override
  State<DreamJournalWidget> createState() => DreamJournalWidgetState();
}

class DreamJournalWidgetState extends State<DreamJournalWidget> {
  List<Dream> _dreams = [];
  Map<int, bool> _expanded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    try {
      final dreams = await ApiService.fetchDreams();
      setState(() {
        _dreams = dreams;
        _loading = false;
      });
    } catch (e) {
      print("❌ Failed to fetch dreams: $e");
      setState(() {
        _loading = false;
      });
    }
  }


  void refresh() {
    setState(() => _loading = true);
    _loadDreams();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_dreams.isEmpty) return const Text("Your Dreams will appear here...");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // remove side gap
      child: ListView.builder(
        padding: EdgeInsets.zero, // remove internal ListView padding
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _dreams.length,

        // this code prints the dreams with no "bubble"
        // itemBuilder: (context, index) {
        //   final dream = _dreams[index];
        //   final isExpanded = _expanded[dream.id] ?? false;
        //   final formattedDate = DateFormat.yMMMd().add_jm().format(dream.createdAt);

        //   return Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       GestureDetector(
        //         onTap: () {
        //           setState(() {
        //             _expanded[dream.id] = !isExpanded;
        //           });
        //         },
        //         child: Padding(
        //           padding: const EdgeInsets.symmetric(vertical: 6.0),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               Text(
        //                 formattedDate,
        //                 style: const TextStyle(fontSize: 12, color: Colors.grey),
        //               ),
        //               Text(
        //                 dream.summary,
        //                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //       if (isExpanded)
        //         Padding(
        //           padding: const EdgeInsets.only(bottom: 12.0),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               if (dream.text.isNotEmpty)
        //                 Padding(
        //                   padding: const EdgeInsets.only(top: 4),
        //                   child: Text(
        //                     dream.text,
        //                     style: const TextStyle(
        //                       fontSize: 13,
        //                       fontStyle: FontStyle.italic,
        //                     ),
        //                   ),
        //                 ),
        //               if (dream.analysis.isNotEmpty)
        //                 Padding(
        //                   padding: const EdgeInsets.only(top: 6),
        //                   child: MarkdownBody(data: dream.analysis),
        //                 ),
        //               if (dream.imageFile != null && dream.imageFile!.isNotEmpty)
        //                 Padding(
        //                   padding: const EdgeInsets.only(top: 6),
        //                   child: Image.network(
        //                     dream.imageFile!,
        //                     errorBuilder: (context, error, stackTrace) =>
        //                         const Text("⚠️ Failed to load image."),
        //                   ),
        //                 ),
        //             ],
        //           ),
        //         ),
        //     ],
        //   );
        // }

        itemBuilder: (context, index) {
          final dream = _dreams[index];
          final isExpanded = _expanded[dream.id] ?? false;
          final formattedDate = DateFormat.yMMMd().add_jm().format(dream.createdAt);

          return SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,                        //color of box for dreams
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expanded[dream.id] = !isExpanded;
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dream.imageTile != null && dream.imageTile!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              dream.imageTile!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                dream.summary,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                  ),

                  if (isExpanded)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dream.text.isNotEmpty) ...[
                          Text(dream.text,
                              style: const TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 6),
                        ],
                        if (dream.analysis.isNotEmpty) ...[
                          const Text("Analysis:",
                              style:
                                  TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          MarkdownBody(data: dream.analysis),
                          const SizedBox(height: 6),
                        ],
                        if (dream.imageFile != null && dream.imageFile!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              dream.imageFile!,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text("⚠️ Failed to load image."),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
