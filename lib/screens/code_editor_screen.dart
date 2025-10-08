import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import '../models/file_node.dart';
import '../services/github_service.dart'; // GitHub service import

class CodeEditorScreen extends StatefulWidget {
  const CodeEditorScreen({super.key});

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> {
  List<FileNode> fileTree = [];
  bool isLoading = true;
  FileNode? selectedFile;
  TextEditingController codeController = TextEditingController();
  DraggableScrollableController bottomSheetController = DraggableScrollableController();

  // GitHub push state
  bool _isPushing = false;
  String _pushStatus = "";

  @override
  void initState() {
    super.initState();
    _loadZipFromAssets();
  }

  @override
  void dispose() {
    codeController.dispose();
    bottomSheetController.dispose();
    super.dispose();
  }

  // ZIP file load from assets and build file tree
  Future<void> _loadZipFromAssets() async {
    try {
      final ByteData data = await rootBundle.load('assets/Hello-World.zip');
      final Archive archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());

      FileNode root = FileNode(name: 'Hello-World', fullPath: '', isFile: false, isExpanded: true);

      for (var file in archive.files) {
        if (file.name.isNotEmpty && !file.name.endsWith('/')) {
          String content = '';
          if (file.isFile) {
            try {
              content = String.fromCharCodes(file.content);
            } catch (e) {
              content = '[Binary file - cannot display]';
            }
          }
          _addToTree(root, file.name, file.isFile, content);
        }
      }

      setState(() {
        fileTree = root.children;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading zip: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addToTree(FileNode node, String filePath, bool isFile, String content) {
    List<String> parts = filePath.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return;

    String currentPart = parts.first;
    String currentPath = node.fullPath.isEmpty ? currentPart : '${node.fullPath}/$currentPart';

    FileNode? existingChild = node.children.cast<FileNode?>().firstWhere(
      (child) => child?.name == currentPart,
      orElse: () => null,
    );

    if (existingChild == null) {
      existingChild = FileNode(
        name: currentPart,
        fullPath: currentPath,
        isFile: parts.length == 1 ? isFile : false,
        content: parts.length == 1 && isFile ? content : null,
        children: [],
      );
      node.children = [...node.children, existingChild];
    }

    if (parts.length > 1) {
      _addToTree(existingChild, parts.sublist(1).join('/'), isFile, content);
    }
  }

  void _onFileSelected(FileNode node) {
    if (node.isFile) {
      setState(() {
        selectedFile = node;
        codeController.text = node.content ?? '';
      });

      codeController.addListener(() {
        if (selectedFile != null) {
          selectedFile!.content = codeController.text;
        }
      });
    }
  }

  // Build tree view for drawer
  Widget _buildTree(List<FileNode> nodes, [int level = 0]) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        bool isSelected = selectedFile?.fullPath == node.fullPath;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: isSelected ? Colors.blue.withOpacity(0.2) : null,
              padding: EdgeInsets.only(left: (level * 10.0), right: 8),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                minLeadingWidth: 0,
                title: Row(
                  children: [
                    if (!node.isFile)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          node.isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    Icon(
                      node.isFile ? Icons.insert_drive_file_outlined : Icons.folder,
                      color: node.isFile ? Colors.blueGrey : Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        node.name,
                        style: TextStyle(
                          fontWeight: node.isFile ? FontWeight.normal : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (!node.isFile) {
                    setState(() {
                      node.isExpanded = !node.isExpanded;
                    });
                  } else {
                    _onFileSelected(node);
                  }
                },
                onLongPress: () {
                  _showFileOptions(context, node.name, node.isFile);
                },
              ),
            ),
            if (!node.isFile && node.isExpanded && node.children.isNotEmpty)
              _buildTree(node.children, level + 1),
          ],
        );
      },
    );
  }

  // GitHub Push function
  Future<void> _pushToGitHub() async {
    setState(() {
      _isPushing = true;
      _pushStatus = "Pushing ZIP to GitHub...";
    });

    try {
      await GitHubService.pushZipFromAssets();
      setState(() {
        _pushStatus = "✅ Push completed successfully!";
      });
    } catch (e) {
      setState(() {
        _pushStatus = "❌ Error: $e";
      });
    } finally {
      setState(() {
        _isPushing = false;
      });

      if (_pushStatus.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_pushStatus)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📂 Flutter Code Editor"),
        backgroundColor: Colors.indigo,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isPushing
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    tooltip: 'Push to GitHub',
                    onPressed: _pushToGitHub,
                  ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Main Code Editor Area
          Container(
            padding: const EdgeInsets.all(16),
            child: selectedFile == null
                ? const Center(
                    child: Text(
                      "Select a file from drawer to edit",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File Name Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_document, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedFile!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  selectedFile = null;
                                  codeController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Code Editor
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: codeController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                              hintText: 'Start coding...',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Sheet
          DraggableScrollableSheet(
            controller: bottomSheetController,
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.4,
            snap: true,
            snapSizes: const [0.1, 0.25, 0.4],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.terminal),
                            title: const Text('Terminal'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Terminal opened')),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.bug_report),
                            title: const Text('Debug'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).show