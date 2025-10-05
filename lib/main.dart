import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

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
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  List<EditorTab> _openTabs = [];
  int _selectedTabIndex = -1;
  String _currentProject = '';
  bool _isIndexing = false;

  // File tree structure
  final List<FileTreeNode> _fileTree = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showBuildOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D30),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.build, color: Colors.green),
              title: const Text('Build release APK'),
              onTap: () {
                Navigator.pop(context);
                _buildProject('release');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('Build debug APK'),
              onTap: () {
                Navigator.pop(context);
                _buildProject('debug');
              },
            ),
            ListTile(
              leading: const Icon(Icons.apps, color: Colors.blue),
              title: const Text('Build AAB'),
              onTap: () {
                Navigator.pop(context);
                _buildProject('aab');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _buildProject(String type) {
    setState(() {
      _isIndexing = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isIndexing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Building $type APK...'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _cloneRepository() {
    final repoController = TextEditingController();
    final tokenController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D30),
        title: const Text('Clone Repository'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repoController,
                decoration: const InputDecoration(
                  labelText: 'Repository URL',
                  hintText: 'https://github.com/username/repo.git',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Access Token (Optional)',
                  hintText: 'ghp_xxxxxxxxxxxxx',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (repoController.text.isNotEmpty) {
                Navigator.pop(context);
                _performClone(repoController.text, tokenController.text);
              }
            },
            child: const Text('Clone'),
          ),
        ],
      ),
    );
  }

  void _performClone(String repoUrl, String token) {
    setState(() {
      _isIndexing = true;
      _currentProject = repoUrl.split('/').last.replaceAll('.git', '');
    });

    // Simulate cloning and file tree creation
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isIndexing = false;
        _fileTree.clear();
        _fileTree.addAll([
          FileTreeNode('app', true, [
            FileTreeNode('build', true, []),
            FileTreeNode('libs', true, []),
            FileTreeNode('src', true, [
              FileTreeNode('main', true, [
                FileTreeNode('java', true, []),
                FileTreeNode('res', true, []),
                FileTreeNode('AndroidManifest.xml', false, []),
              ]),
            ]),
          ]),
          FileTreeNode('gradle', true, [
            FileTreeNode('wrapper', true, [
              FileTreeNode('gradle-wrapper.jar', false, []),
              FileTreeNode('gradle-wrapper.properties', false, []),
            ]),
          ]),
          FileTreeNode('.gitignore', false, []),
          FileTreeNode('build.gradle', false, []),
          FileTreeNode('settings.gradle', false, []),
        ]);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repository cloned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _openFile(FileTreeNode node) {
    if (node.isDirectory) return;
    
    // Check if file is already open
    int existingIndex = _openTabs.indexWhere((tab) => tab.fileName == node.name);
    
    if (existingIndex != -1) {
      setState(() {
        _selectedTabIndex = existingIndex;
        _codeController.text = _openTabs[existingIndex].content;
      });
      return;
    }

    // Open new file
    setState(() {
      String content = _generateSampleContent(node.name);
      _openTabs.add(EditorTab(node.name, content));
      _selectedTabIndex = _openTabs.length - 1;
      _codeController.text = content;
      _tabController = TabController(length: _openTabs.length, vsync: this);
      _tabController.index = _selectedTabIndex;
    });
  }

  String _generateSampleContent(String fileName) {
    if (fileName.endsWith('.java')) {
      return '''package com.ide.editor;

import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

public class MainActivity {
    
}''';
    } else if (fileName.endsWith('.gradle')) {
      return '''plugins {
    id 'com.android.application'
}

android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.ide.editor"
        minSdk 21
        targetSdk 34
    }
}''';
    }
    return '// ${fileName}\n';
  }

  void _closeTab(int index) {
    setState(() {
      _openTabs.removeAt(index);
      if (_selectedTabIndex >= _openTabs.length) {
        _selectedTabIndex = _openTabs.length - 1;
      }
      if (_openTabs.isEmpty) {
        _codeController.clear();
      } else {
        _codeController.text = _openTabs[_selectedTabIndex].content;
      }
      _tabController = TabController(length: _openTabs.length, vsync: this);
      if (_selectedTabIndex >= 0) {
        _tabController.index = _selectedTabIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openDrawer,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ide editor', style: TextStyle(fontSize: 18)),
            if (_isIndexing)
              const Text(
                'Indexing XML files.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _showBuildOptions,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              // Open file manager
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
        bottom: _openTabs.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: const Color(0xFF252526),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.blue,
                    onTap: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                        _codeController.text = _openTabs[index].content;
                      });
                    },
                    tabs: _openTabs.asMap().entries.map((entry) {
                      int index = entry.key;
                      EditorTab tab = entry.value;
                      return Tab(
                        child: Row(
                          children: [
                            Text(tab.fileName),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _closeTab(index),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            : null,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF252526),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentProject.isEmpty ? 'Ide editor' : _currentProject,
                          style: const TextStyle(fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _cloneRepository,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Clone Repository'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
            if (_fileTree.isNotEmpty)
              Expanded(
                child: ListView(
                  children: _buildFileTree(_fileTree, 0),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'No project loaded\nClone a repository to start',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_openTabs.isNotEmpty && _selectedTabIndex >= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF1E1E1E),
              child: Row(
                children: [
                  Text(
                    'Lines: ${_codeController.text.split('\n').length}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _openTabs[_selectedTabIndex].fileName,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _openTabs.isEmpty
                ? const Center(
                    child: Text(
                      'Open a file to start editing',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1E1E1E),
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (text) {
                        if (_selectedTabIndex >= 0) {
                          _openTabs[_selectedTabIndex].content = text;
                        }
                      },
                    ),
                  ),
          ),
          // Bottom toolbar with special characters
          Container(
            height: 48,
            color: const Color(0xFF2D2D30),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildToolbarButton('->'),
                _buildToolbarButton('<'),
                _buildToolbarButton('>'),
                _buildToolbarButton(';'),
                _buildToolbarButton('{'),
                _buildToolbarButton('}'),
                _buildToolbarButton(':'),
                _buildToolbarButton('←'),
              ],
            ),
          ),
          // Bottom tabs
          Container(
            height: 48,
            color: const Color(0xFF252526),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomTab('Build Logs', false),
                _buildBottomTab('App Logs', false),
                _buildBottomTab('Diagnostics', true),
                _buildBottomTab('IDE Logs', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String text) {
    return InkWell(
      onTap: () {
        int cursorPos = _codeController.selection.base.offset;
        String currentText = _codeController.text;
        String newText = currentText.substring(0, cursorPos) +
            text +
            currentText.substring(cursorPos);
        _codeController.text = newText;
        _codeController.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPos + text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildBottomTab(String title, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isSelected ? Colors.orange : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFileTree(List<FileTreeNode> nodes, int depth) {
    List<Widget> widgets = [];
    
    for (var node in nodes) {
      widgets.add(
        InkWell(
          onTap: () => _openFile(node),
          child: Container(
            padding: EdgeInsets.only(left: depth * 16.0 + 8, top: 8, bottom: 8),
            child: Row(
              children: [
                Icon(
                  node.isDirectory ? Icons.folder : Icons.insert_drive_file,
                  size: 18,
                  color: node.isDirectory ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      if (node.isDirectory && node.children.isNotEmpty) {
        widgets.addAll(_buildFileTree(node.children, depth + 1));
      }
    }
    
    return widgets;
  }
}

class FileTreeNode {
  final String name;
  final bool isDirectory;
  final List<FileTreeNode> children;

  FileTreeNode(this.name, this.isDirectory, this.children);
}

class EditorTab {
  final String fileName;
  String content;

  EditorTab(this.fileName, this.content);
}