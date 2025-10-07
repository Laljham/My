import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// 🔹 MAIN APP START
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
// 🔹 MAIN APP END


// 🔹 HOME SCREEN START
class CodeEditorHome extends StatefulWidget {
  const CodeEditorHome({super.key});

  @override
  State<CodeEditorHome> createState() => _CodeEditorHomeState();
}

class _CodeEditorHomeState extends State<CodeEditorHome> {
  // 🔸 Dummy File List (in real app — filesystem se load hoga)
  List<String> files = ["main.dart", "home.dart", "utils/", "theme/"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📂 Flutter Code Editor")),
      drawer: _buildDrawer(), // 🔹 Custom Drawer Widget
      body: const Center(
        child: Text(
          "Code Editor Area (main content)",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // 🔹 DRAWER START
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Text(
              "📁 Project Files",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          for (var file in files)
            ListTile(
              leading: Icon(
                file.endsWith('/')
                    ? Icons.folder
                    : Icons.insert_drive_file_outlined,
                color: file.endsWith('/') ? Colors.amber : Colors.blueGrey,
              ),
              title: Text(file),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Opened: $file")),
                );
              },
              // ✅ Long Press → Popup Menu
              onLongPress: () {
                _showFileOptions(context, file);
              },
            ),
        ],
      ),
    );
  }
  // 🔹 DRAWER END


  // 🔹 FIRST POPUP (New / Rename / Delete)
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
                  Navigator.pop(context); // close this popup
                  _showNewPopup(context); // open second popup
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

  // 🔹 SECOND POPUP (File / Directory)
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

  // 🔹 CREATE DIALOG (File / Folder)
  void _showCreateDialog(BuildContext context, {required bool isFile}) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFile ? 'Create File' : 'Create Folder'),
        backgroundColor: Colors.white70,
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

  // 🔹 RENAME DIALOG
  void _showRenameDialog(BuildContext context, String oldName) {
    final TextEditingController renameController =
        TextEditingController(text: oldName.replaceAll("/", ""));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        backgroundColor: Colors.white70,
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

  // 🔹 DELETE FUNCTION (Demo)
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
// 🔹 HOME SCREEN END
