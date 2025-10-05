import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDE Editor',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D2D30),
          elevation: 0,
        ),
      ),
      home: const IDEHomePage(),
    );
  }
}

class IDEHomePage extends StatefulWidget {
  const IDEHomePage({super.key});

  @override
  State<IDEHomePage> createState() => _IDEHomePageState();
}

class _IDEHomePageState extends State<IDEHomePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _codeController = TextEditingController();
  late TabController _tabController;

  final List<EditorTab> _openTabs = [];
  int _selectedTabIndex = -1;

  final List<FileTreeNode> _fileTree = [];
  final Map<String, bool> _expandedFolders = {};
  bool _isIndexing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _fileTree.addAll(_generateSampleFileTree());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _toggleFolder(String path) {
    setState(() {
      _expandedFolders[path] = !(_expandedFolders[path] ?? false);
    });
  }

  void _openFile(FileTreeNode node) {
    if (node.isDirectory) {
      _toggleFolder(node.path);
      return;
    }

    int existingIndex = _openTabs.indexWhere((tab) => tab.filePath == node.path);
    if (existingIndex != -1) {
      setState(() {
        _selectedTabIndex = existingIndex;
        _codeController.text = _openTabs[existingIndex].content;
        _tabController.index = _selectedTabIndex;
      });
      return;
    }

    setState(() {
      String content = _getFileContent(node.name);
      _openTabs.add(EditorTab(node.name, node.path, content));
      _selectedTabIndex = _openTabs.length - 1;
      _codeController.text = content;
      _tabController = TabController(length: _openTabs.length, vsync: this);
      _tabController.index = _selectedTabIndex;
    });
  }

  void _closeTab(int index) {
    setState(() {
      _openTabs.removeAt(index);
      if (_selectedTabIndex >= _openTabs.length) {
        _selectedTabIndex = _openTabs.length - 1;
      }
      if (_openTabs.isEmpty) {
        _codeController.clear();
        _selectedTabIndex = -1;
      } else if (_selectedTabIndex >= 0) {
        _codeController.text = _openTabs[_selectedTabIndex].content;
      }
      _tabController = TabController(length: _openTabs.length, vsync: this);
      if (_selectedTabIndex >= 0 && _openTabs.isNotEmpty) {
        _tabController.index = _selectedTabIndex;
      }
    });
  }

  String _getFileContent(String fileName) {
    return '// Content of $fileName\n';
  }

  List<FileTreeNode> _generateSampleFileTree() {
    return [
      FileTreeNode('project', true, 'project', [
        FileTreeNode('lib', true, 'project/lib', [
          FileTreeNode('main.dart', false, 'project/lib/main.dart', []),
        ]),
        FileTreeNode('pubspec.yaml', false, 'project/pubspec.yaml', []),
      ]),
    ];
  }

  Widget _buildFileTree(List<FileTreeNode> nodes) {
    return ListView(
      children: nodes.map((node) {
        bool isExpanded = _expandedFolders[node.path] ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(node.isDirectory
                  ? (isExpanded ? Icons.folder_open : Icons.folder)
                  : Icons.insert_drive_file),
              title: Text(node.name),
              onTap: () => _openFile(node),
            ),
            if (node.isDirectory && isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildFileTree(node.children),
              ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('IDE Editor'),
        bottom: _openTabs.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: const Color(0xFF252526),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.orange,
                    tabs: _openTabs
                        .asMap()
                        .entries
                        .map(
                          (entry) => Tab(
                            child: Row(
                              children: [
                                Text(entry.value.fileName),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _closeTab(entry.key),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onTap: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                        _codeController.text = _openTabs[index].content;
                      });
                    },
                  ),
                ),
              )
            : null,
      ),
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFF1B1B1B),
            child: _buildFileTree(_fileTree),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Open a file to start editing...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditorTab {
  final String fileName;
  final String filePath;
  final String content;

  EditorTab(this.fileName, this.filePath, this.content);
}

class FileTreeNode {
  final String name;
  final bool isDirectory;
  final String path;
  final List<FileTreeNode> children;

  FileTreeNode(this.name, this.isDirectory, this.path, this.children);
}