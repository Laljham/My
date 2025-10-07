import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Editor Drawer Demo',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const CodeEditorHome(),
    );
  }
}

// ✅ FILE NODE CLASS (STATE KE BAHAR)
class FileNode {
  String name;
  bool isExpanded;
  bool isFile;
  List<FileNode> children;
  
  FileNode({
    required this.name,
    required this.isFile,
    this.isExpanded = false,
    this.children = const [],
  });
}

class CodeEditorHome extends StatefulWidget {
  const CodeEditorHome({super.key});

  @override
  State<CodeEditorHome> createState() => _CodeEditorHomeState();
}

class _CodeEditorHomeState extends State<CodeEditorHome> {
  List<FileNode> fileTree = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadZipFromAssets();
  }

  Future<void> _loadZipFromAssets() async {
    try {
      final ByteData data = await rootBundle.load('assets/Hello-World.zip');
      final Archive archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
      
      FileNode root = FileNode(name: 'Hello-World', isFile: false, isExpanded: true);
      
      for (var file in archive.files) {
        if (file.name.isNotEmpty) {
          _addToTree(root, file.name, file.isFile);
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

  void _addToTree(FileNode node, String filePath, bool isFile) {
    List<String> parts = filePath.split('/').where((part) => part.isNotEmpty).toList();
    
    if (parts.isEmpty) return;
    
    String currentPart = parts.first;
    String remainingPath = parts.sublist(1).join('/');
    
    // ✅ PROPER WAY TO FIND EXISTING CHILD
    FileNode? existingChild;
    try {
      existingChild = node.children.firstWhere((child) => child.name == currentPart);
    } catch (e) {
      existingChild = null;
    }
    
    if (existingChild == null) {
      existingChild = FileNode(
        name: currentPart,
        isFile: parts.length == 1 ? isFile : false,
      );
      node.children.add(existingChild);
    }
    
    if (remainingPath.isNotEmpty) {
      _addToTree(existingChild, remainingPath, isFile);
    }
  }

  Widget _buildTree(List<FileNode> nodes, [int level = 0]) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(left: (level * 20.0) + 16.0),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  node.isFile ? Icons.insert_drive_file_outlined : Icons.folder,
                  color: node.isFile ? Colors.blueGrey : Colors.amber,
                ),
                title: Text(
                  node.name,
                  style: TextStyle(
                    fontWeight: node.isFile ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                trailing: node.isFile ? null : Icon(
                  node.isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () {
                  if (!node.isFile) {
                    setState(() {
                      node.isExpanded = !node.isExpanded;
                    });
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Opened: ${node.name}")),
                    );
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
      appBar: AppBar(title: const Text("📂 Flutter Code Editor")),
      drawer: _buildDrawer(),
      body: const Center(
        child: Text("Code Editor Area (main content)"),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "📁 Project Structure",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          const Divider(),
          
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: _buildTree(fileTree),
            ),
        ],
      ),
    );
  }

  // ✅ BAKI KE FUNCTIONS SAME RAHENGE
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
        title: const Text('Delete'),
        content: Text('Do you want to delete "$fileName"?'),
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