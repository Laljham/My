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
  List<FileNode> openFiles = []; // Multiple open files
  FileNode? selectedFile;
  Map<String, TextEditingController> controllers = {}; // Each file ka apna controller
  DraggableScrollableController bottomSheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadZipFromAssets();
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    bottomSheetController.dispose();
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

  // 🔹 FILE SELECT KARNE PAR
  void _onFileSelected(FileNode node) {
    if (node.isFile) {
      // Check if already open
      bool alreadyOpen = openFiles.any((file) => file.fullPath == node.fullPath);
      
      if (!alreadyOpen) {
        // New controller for this file
        controllers[node.fullPath] = TextEditingController(text: node.content ?? '');
        
        // Auto-save listener
        controllers[node.fullPath]!.addListener(() {
          node.content = controllers[node.fullPath]!.text;
        });
        
        setState(() {
          openFiles.add(node);
        });
      }
      
      setState(() {
        selectedFile = node;
      });
    }
  }

  // 🔹 FILE CLOSE KARNE PAR
  void _closeFile(FileNode file) {
    setState(() {
      openFiles.removeWhere((f) => f.fullPath == file.fullPath);
      controllers[file.fullPath]?.dispose();
      controllers.remove(file.fullPath);
      
      if (selectedFile?.fullPath == file.fullPath) {
        selectedFile = openFiles.isNotEmpty ? openFiles.last : null;
      }
    });
  }

  // 🔹 LINE NUMBERS AUTOMATIC CALCULATE
  int _getLineCount() {
    if (selectedFile == null || controllers[selectedFile!.fullPath] == null) {
      return 1;
    }
    String text = controllers[selectedFile!.fullPath]!.text;
    return text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
  }

  // 🔹 LINE NUMBERS KE SAATH CODE EDITOR
  Widget _buildCodeEditorWithLineNumbers() {
    if (selectedFile == null) {
      return Center(
        child: Text(
          "Select a file from drawer",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }
    
    int lineCount = _getLineCount();
    TextEditingController currentController = controllers[selectedFile!.fullPath]!;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line Numbers
        Container(
          width: 50,
          color: Colors.grey[900],
          child: ListView.builder(
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
              controller: currentController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.white,
                height: 1.43,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                hintText: 'Start coding...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (text) {
                // Trigger rebuild to update line numbers
                setState(() {});
              },
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
                    // Expand/Collapse Arrow
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
                    
                    // Icon
                    Icon(
                      node.isFile 
                        ? Icons.insert_drive_file_outlined 
                        : (node.isExpanded ? Icons.folder_open : Icons.folder),
                      color: node.isFile ? Colors.grey[500] : Colors.amber[700],
                      size: 16,
                    ),
                    
                    const SizedBox(width: 6),
                    
                    // Name
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
            
            // Children
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
        title: const Text("Flutter", style: TextStyle(fontSize: 16)),
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
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Main Editor Area
          Column(
            children: [
              // Tab Bar (Multiple Files)
              if (openFiles.isNotEmpty)
                Container(
                  height: 35,
                  color: Colors.grey[800],
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: openFiles.length,
                    itemBuilder: (context, index) {
                      final file = openFiles[index];
                      bool isActive = selectedFile?.fullPath == file.fullPath;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedFile = file;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.grey[850] : Colors.transparent,
                            border: Border(
                              right: BorderSide(color: Colors.grey[700]!, width: 1),
                              bottom: isActive 
                                ? const BorderSide(color: Colors.blue, width: 2)
                                : BorderSide.none,
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
                                file.name,
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _closeFile(file),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              // Code Editor
              Expanded(
                child: _buildCodeEditorWithLineNumbers(),
              ),
            ],
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
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 35,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
      title: Text(title, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
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
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: _buildTree(fileTree),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
                const SnackBar(content: Text('Renamed successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteFile(String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Delete', style: TextStyle(color: Colors.white)),
        content: Text(
          'Do you want to delete "$fileName"?',
          style: const TextStyle(color: Colors.white70),
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
                const SnackBar(content: Text('Deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}