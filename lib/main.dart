import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Code Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: CodeEditorPage(),
    );
  }
}

class CodeEditorPage extends StatefulWidget {
  const CodeEditorPage({super.key});

  @override
  _CodeEditorPageState createState() => _CodeEditorPageState();
}

class _CodeEditorPageState extends State<CodeEditorPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedLanguage = 'Dart';
  double _fontSize = 14.0;
  bool _showLineNumbers = true;
  List<String> _recentFiles = [];

  final List<String> _languages = [
    'Dart',
    'Python',
    'JavaScript',
    'Java',
    'C++',
    'HTML',
    'CSS',
    'JSON',
  ];

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _newFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: const Text('Create a new file? Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _controller.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _saveFile() {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Save File'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter file name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _recentFiles.insert(0, nameController.text);
                    if (_recentFiles.length > 10) {
                      _recentFiles.removeLast();
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved as ${nameController.text}')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard!')),
    );
  }

  void _pasteCode() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _controller.text = data!.text!;
      });
    }
  }

  void _clearCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Code'),
        content: const Text('Are you sure you want to clear all code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _controller.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Code Editor'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openDrawer,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openEndDrawer,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'new':
                  _newFile();
                  break;
                case 'save':
                  _saveFile();
                  break;
                case 'copy':
                  _copyCode();
                  break;
                case 'paste':
                  _pasteCode();
                  break;
                case 'clear':
                  _clearCode();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new', child: Text('New File')),
              const PopupMenuItem(value: 'save', child: Text('Save File')),
              const PopupMenuItem(value: 'copy', child: Text('Copy Code')),
              const PopupMenuItem(value: 'paste', child: Text('Paste Code')),
              const PopupMenuItem(value: 'clear', child: Text('Clear Code')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.code, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Code Editor',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('New File'),
              onTap: () {
                Navigator.pop(context);
                _newFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Save File'),
              onTap: () {
                Navigator.pop(context);
                _saveFile();
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Recent Files',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_recentFiles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No recent files',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._recentFiles.map(
                (file) => ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(file),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening $file')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.settings, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Settings',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Language',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: _languages
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Font Size',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _fontSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    label: _fontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('Show Line Numbers'),
              value: _showLineNumbers,
              onChanged: (value) {
                setState(() {
                  _showLineNumbers = value;
                });
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.code, size: 16),
                  label: Text(_selectedLanguage),
                  backgroundColor: Colors.blue,
                ),
                const Spacer(),
                Text(
                  'Lines: ${_controller.text.split('\n').length}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Start typing your code here...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy',
              onPressed: _copyCode,
            ),
            IconButton(
              icon: const Icon(Icons.paste),
              tooltip: 'Paste',
              onPressed: _pasteCode,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: _saveFile,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear',
              onPressed: _clearCode,
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Run',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Run feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}