import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import '../models/file_node.dart';

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
  ScrollController lineNumberController = ScrollController();
  ScrollController codeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadZipFromAssets();
    
    // Sync scroll between line numbers and code
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
    lineNumberController.dispose();
    codeScrollController.dispose();
    super.dispose();
  }

  // 🔹 ZIP SE TREE BANAYE
  Future<void> _loadZipFromAssets() async {
    try {
      final ByteData data = await rootBundle.load('assets/Hello-World.zip');
      final Archive archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
      
      FileNode root = FileNode(name: 'Root', fullPath: '', isFile: false, isExpanded: true);
      
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

  // 🔹 TREE STRUCTURE BANANE KA FUNCTION
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

  // 🔹 FILE SELECT KARNE PAR
  void _onFileSelected(FileNode node) {
    if (node.isFile) {
      setState(() {
        selectedFile = node;
        codeController.text = node.content ?? '';
      });
      
      // Auto save on text change
      codeController.addListener(() {
        if (selectedFile != null) {
          selectedFile!.content = codeController.text;
        }
      });
    }
  }

  // 🔹 LINE NUMBERS KE SAATH CODE EDITOR
  Widget _buildCodeEditorWithLineNumbers() {
    int lineCount = '\n'.allMatches(codeController.text).length + 1;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Numbers
        Container(
          width: 50,
          color: Colors.grey[900],
          child: ListView.builder(
            controller: lineNumberController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lineCount,
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
        
        // Code Editor
        Expanded(
          child: Container(
            color: Colors.grey[850],
            child: TextField(
              controller: codeController,
              scrollController: codeScrollController,
              maxLines: null,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.white,
                height: 1.43, // Match line number height
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                hintText: 'Start coding...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 TREE WIDGET (VS CODE STYLE - COMPACT)
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
                color: isSelected ? Colors.grey[800] : null,
                padding: EdgeInsets.only(
                  left: (level * 12.0) + 4.0,
                  top: 4,
                  bottom: 4,
                ),
                child: Row(
                  children: [
                    // Expand/Collapse Arrow (LEFT SIDE)
                    if (!node.isFile)
                      Icon(
                        node.isExpanded 
                          ? Icons.keyboard_arrow_down 
                          : Icons.keyboard_arrow_right,
                        size: 16,
                        color: Colors.grey[400],
                      )
                    else
                      const SizedBox(width: 16),
                    
                    const SizedBox(width: 4),
                    
                    // Folder/File Icon
                    Icon(
                      node.isFile 
                        ? Icons.insert_drive_file_outlined 
                        : (node.isExpanded ? Icons.folder_open : Icons.folder),
                      color: node.isFile ? Colors.grey[500] : Colors.amber[700],
                      size: 16,
                    ),
                    
                    const SizedBox(width: 6),
                    
                    // File/Folder Name
                    Expanded(
                      child: Text(
                        node.name,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontWeight: node.isFile ? FontWeight.normal : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Children (Recursive)
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          selectedFile?.name ?? "Flutter",
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.grey[850],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Run button pressed')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Main Code Editor Area
          Container(
            child: selectedFile == null
                ? Center(
                    child: Text(
                      "Select a file from drawer",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : Column(
                    children: [
                      // Tab Bar (file tabs)
                      Container(
                        height: 35,
                        color: Colors.grey[800],
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                border: Border(
                                  right: BorderSide(color: Colors.grey[700]!, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    selectedFile!.name,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedFile = null;
                                        codeController.clear();
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Code Editor with Line Numbers
                      Expanded(
                        child: _buildCodeEditorWithLineNumbers(),
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
                  color: Colors.grey[850],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 35,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Bottom Sheet Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildBottomSheetItem(Icons.terminal, 'Terminal'),
                          _buildBottomSheetItem(Icons.bug_report, 'Debug'),
                          _buildBottomSheetItem(Icons.search, 'Search'),
                          _buildBottomSheetItem(Icons.output, 'Output'),
                          _buildBottomSheetItem(Icons.settings, 'Settings'),
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

  Widget _buildBottomSheetItem(IconData icon, String title) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.grey[400], size: 20),
      title: Text(
        title,
        style: TextStyle(color: Colors.grey[300], fontSize: 14),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[600]),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title opened')),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        children: [
          // NO HEADER - Direct file tree
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40), // Status bar padding
                  child: _buildTree(fileTree),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 FILE OPTIONS (SAME AS BEFORE)
  void _showFileOptions(BuildContext context, String fileName, bool isFile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined, color: Colors.white70),
                title: const Text('New', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _showNewPopup(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white70),
                title: const Text('Rename', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, fileName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
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
      backgroundColor: Colors.grey[850],
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.white70),
                title: const Text('File', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(context, isFile: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder, color: Colors.white70),
                title: const Text('Directory', style: TextStyle(color: Colors.white70)),
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
        backgroundColor: Colors.grey[850],
        title: Text(
          isFile ? 'Create File' : 'Create Folder',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isFile ? 'File name' : 'Folder name',
            hintStyle: TextStyle(color: Colors.grey[600]),
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
        backgroundColor: Colors.grey[850],
        title: const Text('Rename', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: renameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new name',
      