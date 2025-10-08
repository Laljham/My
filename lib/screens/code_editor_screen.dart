import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import '../models/file_node.dart';

class CodeEditorScreen extends StatefulWidget {
  const CodeEditorScreen({super.key});

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> with TickerProviderStateMixin {
  List<FileNode> fileTree = [];
  bool isLoading = true;
  FileNode? selectedFile;
  TextEditingController codeController = TextEditingController();
  DraggableScrollableController bottomSheetController = DraggableScrollableController();
  late TabController tabController;
  List<String> openedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadZipFromAssets();
    tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    codeController.dispose();
    bottomSheetController.dispose();
    tabController.dispose();
    super.dispose();
  }

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
      // 🔹 Preserve zip order
      node.children.add(existingChild);
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
        if (!openedFiles.contains(node.fullPath)) openedFiles.add(node.fullPath);
        tabController = TabController(length: openedFiles.length, vsync: this);
      });

      codeController.addListener(() {
        if (selectedFile != null) {
          selectedFile!.content = codeController.text;
        }
      });
    }
  }

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
              padding: EdgeInsets.only(left: level * 10.0, right: 8, top: 2.0, bottom: 2.0),
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
                          node.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                      ),
                    Icon(
                      node.isFile ? Icons.insert_drive_file_outlined : Icons.folder,
                      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📂 Flutter Code Editor"),
        backgroundColor: Colors.indigo,
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // 🔹 TabBar for opened files
          if (openedFiles.isNotEmpty)
            Container(
              color: Colors.grey[200],
              height: 40,
              child: TabBar(
                controller: tabController,
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: openedFiles.map((f) => Tab(text: f.split('/').last)).toList(),
                onTap: (index) {
                  // Switch file
                  String path = openedFiles[index];
                  FileNode? node = _findNodeByPath(fileTree, path);
                  if (node != null) _onFileSelected(node);
                },
              ),
            ),

          // 🔹 Editor area with line numbers
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  color: Colors.grey[200],
                  child: SingleChildScrollView(
                    controller: ScrollController(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        codeController.text.split('\n').length,
                        (index) => Text('${index + 1}', style: const TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: codeController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Start coding...',
                      ),
                      onChanged: (_) {
                        setState(() {}); // Update line numbers
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Bottom Sheet with shortcut buttons
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: () {}, child: const Text('Ctrl')),
                        ElevatedButton(onPressed: () {}, child: const Text('Alt')),
                        ElevatedButton(onPressed: () {}, child: const Text('Shift')),
                        ElevatedButton(onPressed: () {}, child: const Text('Run')),
                      ],
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Debug panel opened')),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.search),
                            title: const Text('Search in Files'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Search opened')),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Settings'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Settings opened')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                child: _buildTree(fileTree),
              ),
            ),
        ],
      ),
    );
  }

  FileNode? _findNodeByPath(List<FileNode> nodes, String path) {
    for (var node in nodes) {
      if (node.fullPath == path) return node;
      if (!node.isFile) {
        var child = _findNodeByPath(node.children, path);
        if (child != null) return child;
      }
    }
    return null;
  }

  void _showFileOptions(BuildContext context, String fileName, bool isFile) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('New'),
                onTap: () {
                  Navigator.pop(context);
                  _showNewPopup(context);
                },