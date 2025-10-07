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

class CodeEditorHome extends StatefulWidget {
  const CodeEditorHome({super.key});

  @override
  State<CodeEditorHome> createState() => _CodeEditorHomeState();
}

class _CodeEditorHomeState extends State<CodeEditorHome> {
  List<String> files = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadZipFromAssets(); // App start hote hi zip load ho jayega
  }

  // 🔹 ZIP FILE LOAD KARNE WALA FUNCTION
  Future<void> _loadZipFromAssets() async {
    try {
      print("Loading ZIP file from assets...");
      
      // 1. Assets se zip file load karo
      final ByteData data = await rootBundle.load('assets/Hello-World.zip');
      
      // 2. ZIP decode karo
      final Archive archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
      
      // 3. Saari files list mein daalo (sorted)
      setState(() {
        files = archive.files
            .where((file) => file.name.isNotEmpty)
            .map((file) {
              if (file.isFile) {
                return file.name;
              } else {
                return '${file.name}/';
              }
            })
            .toList()
          ..sort(); // Alphabetically sort karo
          
        isLoading = false;
      });
      
      print("Total files loaded: ${files.length}");
      
    } catch (e) {
      print('Error loading zip: $e');
      setState(() {
        isLoading = false;
      });
    }
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
          // Header
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
          
          // File List
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: ListView(
                children: [
                  for (var file in files)
                    ListTile(
                      leading: Icon(
                        file.endsWith('/') ? Icons.folder : Icons.insert_drive_file_outlined,
                        color: file.endsWith('/') ? Colors.amber : Colors.blueGrey,
                      ),
                      title: Text(
                        file,
                        style: TextStyle(
                          fontWeight: file.endsWith('/') ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Opened: $file")),
                        );
                      },
                      onLongPress: () {
                        _showFileOptions(context, file);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 BAKI SAB POPUP FUNCTIONS YAHAN SE START (SAME RAHEGA)
  void _showFileOptions(BuildContext context, String fileName) {
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
              setState(() {
                String newItem = nameController.text.trim();
                if (newItem.isNotEmpty) {
                  files.add(isFile ? newItem : "$newItem/");
                }
              });
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
    final TextEditingController renameController =
        TextEditingController(text: oldName.replaceAll("/", ""));
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
              setState(() {
                int index = files.indexOf(oldName);
                if (index != -1) {
                  files[index] = oldName.endsWith('/')
                      ? "${renameController.text}/"
                      : renameController.text;
                }
              });
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
              setState(() {
                files.remove(fileName);
              });
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