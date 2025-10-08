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
  TabController? tabController;
  List<String> openedFiles = [];
  
  // 🔹 Scroll controllers for sync
  ScrollController lineNumberController = ScrollController();
  ScrollController codeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadZipFromAssets();
    
    // Sync scroll
    codeScrollController.addListener(() {
      if (lineNumberController.hasClients) {
        lineNumberController.jumpTo(codeScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    codeController.dispose();
    bottomSheetController.dispose();
    tabController?.dispose();
    lineNumberController.dispose();
    codeScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadZipFromAssets() async {
    try {
      print('🔄 Loading zip...');
      final ByteData data = await rootBundle.load('assets/Hello-World.zip');
      print('✅ Zip loaded: ${data.lengthInBytes} bytes');
      
      final Archive archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
      print('✅ Files in zip: ${archive.files.length}');

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
      
      print('✅ Tree ready with ${fileTree.length} items');
    } catch (e) {
      print('❌ Error: $e');
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

    FileNode? existingChild;
    try {
      existingChild = node.children.firstWhere((child) => child.name == currentPart);
    } catch (e) {
      existingChild = null;
    }

    if (existingChild == null) {
      existingChild = FileNode(
        name: currentPart,
        fullPath: currentPath,
        isFile: parts.length == 1 ? isFile : false,
        content: parts.length == 1 && isFile ? content : null,
        children: [],
      );
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
        
        if (!openedFiles.contains(node.fullPath)) {
          openedFiles.add(node.fullPath);
          
          // 🔹 Recreate TabController only when tabs change
          tabController?.dispose();
          tabController = TabController(
            length: openedFiles.length,
            vsync: this,
            initialIndex: openedFiles.length - 1,
          );
        } else {
          // Switch to existing tab
          int index = openedFiles.indexOf(node.fullPath);
          tabController?.animateTo(index);
        }
      });

      codeController.addListener(() {
        if (selectedFile != null) {
          selectedFile!.content = codeController.text;
        }
      });
    }
  }

  void _closeTab(String path) {
    setState(() {
      openedFiles.remove(path);
      
      if (openedFiles.isEmpty) {
        selectedFile = null;
        codeController.clear();
        tabController?.dispose();
        tabController = null;
      } else {
        tabController?.dispose();
        tabController = TabController(length: openedFiles.length, vsync: this);
        
        // Select last file
        FileNode? lastNode = _findNodeByPath(fileTree, openedFiles.last);
        if (lastNode != null) {
          selectedFile = lastNode;
          codeController.text = lastNode.content ?? '';
        }
      }
    });
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
            InkWell(
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
              child: Container(
                color: isSelected ? Colors.blue.withOpacity(0.2) : null,
                padding: EdgeInsets.only(left: level * 12.0 + 8, right: 8, top: 6, bottom: 6),
                child: Row(
                  children: [
                    if (!node.isFile)
                      Icon(
                        node.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                        size: 18,
                        color: Colors.grey[700],
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 4),
                    Icon(
                      node.isFile ? Icons.insert_drive_file_outlined : Icons.folder,
                      color: node.isFile ? Colors.grey[700] : Colors.amber[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        node.name,
                        style: TextStyle(
                          fontWeight: node.isFile ? FontWeight.normal : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
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
      body: Stack(
        children: [
          // Main editor area
          Column(
            children: [
              // 🔹 TabBar for opened files
              if (openedFiles.isNotEmpty && tabController != null)
                Container(
                  color: Colors.grey[200],
                  height: 40,
                  child: TabBar(
                    controller: tabController,
                    isScrollable: true,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: openedFiles.map((f) {
                      return Tab(
                        child: Row(
                          children: [
                            Text(f.split('/').last),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _closeTab(f),
                              child: const Icon(Icons.close, size: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onTap: (index) {
                      String path = openedFiles[index];
                      FileNode? node = _findNodeByPath(fileTree, path);
                      if (node != null) {
                        setState(() {
                          selectedFile = node;
                          codeController.text = node.content ?? '';
                        });
                      }
                    },
                  ),
                ),

              // 🔹 Editor area with line numbers
              Expanded(
                child: selectedFile == null
                    ? const Center(child: Text('Select a file from drawer'))
                    : Row(
                        children: [
                          // Line numbers
                          Container(
                            width: 50,
                            color: Colors.grey[200],
                            child: ListView.builder(
                              controller: lineNumberController,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: codeController.text.split('\n').length,
                              itemBuilder: (context, index) {
                                return Container(
                                  height: 20,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Code editor
                          Expanded(
                            child: TextField(
                              controller: codeController,
                              scrollController: codeScrollController,
                              maxLines: null,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                height: 1.43,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                                hintText: 'Start coding...',
                              ),
                              onChanged: (_) {
                                setState(() {}); // Update line numbers
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),

          // 🔹 Bottom Sheet
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
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.bug_report),
                            title: const Text('Debug'),
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.search),
                            title: const Text('Search'),
                            onTap: () {},
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
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 40),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Files: ${fileTree.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (fileTree.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('No files found'),
                    Text('Check console', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            )
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
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, fileName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteFile(fileName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNewPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(context, isFile: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Directory'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(context, isFile: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, {required bool isFile}) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFile ? 'Create File' : 'Create Folder'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: isFile ? 'File name' : 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${isFile ? 'File' : 'Folder'} created")),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String oldName) {
    final TextEditingController renameController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const