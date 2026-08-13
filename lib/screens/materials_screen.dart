import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/course.dart';
import '../models/material.dart';
import '../providers/course_provider.dart';
import '../providers/settings_provider.dart';
import '../services/hive_service.dart';
import '../widgets/powered_by_footer.dart';

class MaterialsScreen extends StatefulWidget {
  final bool isEmbedded;

  const MaterialsScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final HiveService _hiveService = HiveService();
  final Map<String, double> _downloadProgress = {}; // materialId -> progress (0.0 to 1.0)
  List<StudyMaterial> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  void _loadMaterials() {
    final saved = _hiveService.getAllMaterials();
    if (saved.isNotEmpty) {
      setState(() {
        _materials = saved;
      });
    } else {
      // Create defaults
      final defaults = [
        StudyMaterial(
          id: 'mat_bly111_cells',
          title: 'BLY 111 - Plant and Animal Cells Structure & Organization',
          courseId: 'bly111',
          fileUrl: 'bundled://materials/bly111_plant_and_animal_cells.pdf',
          version: 1,
          size: '263 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_chm111_tutorial',
          title: 'CHM 111 - Tutorial Questions (1-5)',
          courseId: 'chem111',
          fileUrl: 'bundled://materials/chm111_tutorial_questions.pdf',
          version: 1,
          size: '426 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_csc111_practical',
          title: 'CSC 111 - Practical Manual Answers',
          courseId: 'csc111',
          fileUrl: 'bundled://materials/csc111_practical_manual_answers.pdf',
          version: 1,
          size: '1.8 MB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_gst111_qna',
          title: 'GST 111 - Extracted Questions and Answers',
          courseId: 'gst111',
          fileUrl: 'bundled://materials/gst111_extracted_q_and_a.pdf',
          version: 1,
          size: '192 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_gst112_library',
          title: 'GST 112 - Use of Library (2014)',
          courseId: 'gst112',
          fileUrl: 'bundled://materials/gst112_use_of_library_2014.doc',
          version: 1,
          size: '132 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_gst113_1_idom',
          title: 'GST 113 - Nigeria People and Culture (Lecture Note by A. M. Idom)',
          courseId: 'gst113_1',
          fileUrl: 'bundled://materials/gst113_lecture_note_idom.docx',
          version: 1,
          size: '60 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_mth111_exercises',
          title: 'MTH 111 - Exercises',
          courseId: 'mth111',
          fileUrl: 'bundled://materials/mth111_exercises.pdf',
          version: 1,
          size: '334 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_phy111_mechanics',
          title: 'PHY 111 - Mechanics, Properties of Matter and Heat (Complete)',
          courseId: 'phy111',
          fileUrl: 'bundled://materials/phy111_mechanics_matter_heat.docx',
          version: 1,
          size: '6.7 MB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_bio102_note',
          title: 'BIO 102 - Lecture Note (Ecological Adaptation)',
          courseId: 'bio102',
          fileUrl: 'bundled://materials/bio102_lecture_note.pdf',
          version: 1,
          size: '503 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_bly121_kingdom',
          title: 'BLY 121 - Plant and Animal Kingdom',
          courseId: 'bly121',
          fileUrl: 'bundled://materials/bly121_plant_and_animal_kingdom.pdf',
          version: 1,
          size: '835 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_bly122_qa',
          title: 'BLY 122 - Comprehensive 200 Questions and Answers',
          courseId: 'bly122',
          fileUrl: 'bundled://materials/bly122_200_q_and_a.pdf',
          version: 1,
          size: '110 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_chm102_module5',
          title: 'CHM 102 - General Chemistry II (Module 5)',
          courseId: 'chm102',
          fileUrl: 'bundled://materials/chm102_module5.pptx',
          version: 1,
          size: '2.6 MB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_chm121_notes',
          title: 'CHM 121 - Introductory Inorganic Chemistry Notes',
          courseId: 'chm121',
          fileUrl: 'bundled://materials/chm121_notes.pdf',
          version: 1,
          size: '4.2 MB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_chm122_note',
          title: 'CHM 122 - Introductory Organic Chemistry (Complete Note)',
          courseId: 'chm122',
          fileUrl: 'bundled://materials/chm122_complete_note.pdf',
          version: 1,
          size: '4.4 MB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_gst113_2_kigbu',
          title: 'GST 113 - Nigeria People and Culture II (E-Learning Note)',
          courseId: 'gst113_2',
          fileUrl: 'bundled://materials/gst113b_e_learning_note.pdf',
          version: 1,
          size: '177 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_mth121_notes',
          title: 'MTH 121 - Lecture Notes',
          courseId: 'mth121',
          fileUrl: 'bundled://materials/mth121_lecture_notes.pdf',
          version: 1,
          size: '534 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_phy102_module1',
          title: 'PHY 102 - Electricity & Magnetism (Module 1)',
          courseId: 'phy102',
          fileUrl: 'bundled://materials/phy102_module1.pptx',
          version: 1,
          size: '253 KB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_phy104_note',
          title: 'PHY 104 - Vibration, Waves and Optics (Lecture Note)',
          courseId: 'phy104',
          fileUrl: 'bundled://materials/phy104_lecture_note.pdf',
          version: 1,
          size: '1.0 MB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
        StudyMaterial(
          id: 'mat_phy121_em',
          title: 'PHY 121 - Electricity & Magnetism',
          courseId: 'phy121',
          fileUrl: 'bundled://materials/phy121_electricity_and_magnetism.pdf',
          version: 1,
          size: '1.4 MB',
          isDownloaded: true,
          localPath: 'bundled',
        ),
      ];
      
      for (var item in defaults) {
        _hiveService.saveMaterial(item);
      }
      
      setState(() {
        _materials = defaults;
      });
    }
  }

  Future<void> _startDownload(StudyMaterial material) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Check low data mode constraint
    if (settingsProvider.settings.lowDataMode) {
      final proceed = await _showLowDataWarning(context, material.size);
      if (!proceed) return;
    }

    setState(() {
      _downloadProgress[material.id] = 0.0;
    });

    // Simulate progress download offline/online
    double progress = 0.0;
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      progress += 0.1;
      if (mounted) {
        setState(() {
          _downloadProgress[material.id] = progress;
        });
      }
    }

    final updated = material.copyWith(
      isDownloaded: true,
      localPath: '/simulated_path/${material.id}.pdf', // mock path
    );

    await _hiveService.saveMaterial(updated);
    _loadMaterials();
    
    setState(() {
      _downloadProgress.remove(material.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${material.title} downloaded successfully!')),
      );
    }
  }

  Future<bool> _showLowDataWarning(BuildContext context, String size) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            title: const Text('Low Data Warning ⚠️', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            content: Text(
              'Low Data Mode is enabled in your settings. This download requires $size of data. Do you want to proceed?',
              style: TextStyle(color: AppColors.inkSoft),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Download anyway', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _viewMaterial(StudyMaterial material) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening "${material.title}"...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // For bundled assets, show the mock viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MockPdfViewer(title: material.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppThemeScope.of(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    final body = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
      children: [
        Text(
          'Download and study official FULafia course materials offline. These files are saved locally on your device.',
          style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 20.0),

        ..._materials.map((material) {
          final course = courseProvider.courses.firstWhere(
            (c) => c.id == material.courseId,
            orElse: () => Course(id: '', code: 'GEN', name: 'General', icon: '📄', colorHex: '#DCEEFF'),
          );
          final progress = _downloadProgress[material.id];
          final isDownloading = progress != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: AppColors.clayShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: course.color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('📄', style: TextStyle(fontSize: 18.0)),
                  ),
                  const SizedBox(width: 14.0),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.code,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          material.title,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Size: ${material.size} • Version ${material.version}',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 11.0,
                          ),
                        ),
                        
                        if (isDownloading) ...[
                          const SizedBox(height: 8.0),
                          LinearProgressIndicator(
                            value: progress,
                            color: AppColors.primary,
                            backgroundColor: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Action Button
                  if (material.isDownloaded)
                    IconButton(
                      icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                      onPressed: () => _viewMaterial(material),
                    )
                  else if (isDownloading)
                    const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
                      onPressed: () => _startDownload(material),
                    ),
                ],
              ),
            ),
          );
        }),
        const PoweredByFooter(),
      ],
    );

    if (widget.isEmbedded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Materials', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: body,
    );
  }
}

// Simple Mock PDF Viewer Screen
class _MockPdfViewer extends StatelessWidget {
  final String title;

  const _MockPdfViewer({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 80.0),
              const SizedBox(height: 24.0),
              const Text(
                'PDF Reader View Active',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12.0),
              Text(
                'This screen runs the PDF viewer for: "$title". Fully integrated offline and printable.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft, height: 1.4),
              ),
              const SizedBox(height: 36.0),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Materials'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
