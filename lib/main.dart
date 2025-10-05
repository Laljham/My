import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ide editor',
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
  List<EditorTab> _openTabs = [];
  int _selectedTabIndex = -1;
  String _currentProject = '';
  String _currentProjectPath = '';
  bool _isIndexing = false;

  // File tree structure
  final List<FileTreeNode> _fileTree = [];
  final Map<String, bool> _expandedFolders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D30),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2D2D30),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Build Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.build_circle, color: Colors.green),
                title: const Text('Build release APK'),
                onTap: () {
                  Navigator.pop(context);
                  _buildProject('release APK');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('Build debug APK'),
                onTap: () {
                  Navigator.pop(context);
                  _buildProject('debug APK');
                },
              ),
              ListTile(
                leading: const Icon(Icons.android, color: Colors.blue),
                title: const Text('Build AAB'),
                onTap: () {
                  Navigator.pop(context);
                  _buildProject('AAB');
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Project Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.yellow),
                title: const Text('Open Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _openLocalFolder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download, color: Colors.blue),
                title: const Text('Clone Repository'),
                onTap: () {
                  Navigator.pop(context);
                  _cloneRepository();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.green),
                title: const Text('Refresh Project'),
                onTap: () {
                  Navigator.pop(context);
                  _refreshProject();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Close Project'),
                onTap: () {
                  Navigator.pop(context);
                  _closeProject();
                },
              ),
            ],
          ),
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
          content: Text('Building $type...'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _openLocalFolder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D30),
        title: const Text('Open Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter folder path:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: '/storage/emulated/0/Projects',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              onSubmitted: (path) {
                Navigator.pop(context);
                _loadLocalFolder(path);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLocalFolder('/storage/emulated/0/');
            },
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }

  void _loadLocalFolder(String path) {
    setState(() {
      _isIndexing = true;
      _currentProject = path.split('/').last;
      _currentProjectPath = path;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isIndexing = false;
        _fileTree.clear();
        _fileTree.addAll(_generateSampleFileTree());
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder loaded successfully!'),
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
      _currentProjectPath = '/storage/emulated/0/${_currentProject}';
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isIndexing = false;
        _fileTree.clear();
        _fileTree.addAll(_generateSampleFileTree());
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repository cloned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  List<FileTreeNode> _generateSampleFileTree() {
    return [
      FileTreeNode(
        'Ide editor',
        true,
        'Ide editor',
        [
          FileTreeNode('app', true, 'Ide editor/app', [
            FileTreeNode('build', true, 'Ide editor/app/build', []),
            FileTreeNode('libs', true, 'Ide editor/app/libs', []),
            FileTreeNode('src', true, 'Ide editor/app/src', [
              FileTreeNode('main', true, 'Ide editor/app/src/main', [
                FileTreeNode('java', true, 'Ide editor/app/src/main/java', [
                  FileTreeNode('com', true, 'Ide editor/app/src/main/java/com', [
                    FileTreeNode('ide', true, 'Ide editor/app/src/main/java/com/ide', [
                      FileTreeNode('editor', true, 'Ide editor/app/src/main/java/com/ide/editor', [
                        FileTreeNode('MainActivity.java', false, 'Ide editor/app/src/main/java/com/ide/editor/MainActivity.java', []),
                        FileTreeNode('FileTreeActivity.java', false, 'Ide editor/app/src/main/java/com/ide/editor/FileTreeActivity.java', []),
                        FileTreeNode('ProjectAdapter.java', false, 'Ide editor/app/src/main/java/com/ide/editor/ProjectAdapter.java', []),
                      ]),
                    ]),
                  ]),
                ]),
                FileTreeNode('res', true, 'Ide editor/app/src/main/res', []),
                FileTreeNode('AndroidManifest.xml', false, 'Ide editor/app/src/main/AndroidManifest.xml', []),
              ]),
            ]),
          ]),
          FileTreeNode('gradle', true, 'Ide editor/gradle', [
            FileTreeNode('wrapper', true, 'Ide editor/gradle/wrapper', [
              FileTreeNode('gradle-wrapper.jar', false, 'Ide editor/gradle/wrapper/gradle-wrapper.jar', []),
              FileTreeNode('gradle-wrapper.properties', false, 'Ide editor/gradle/wrapper/gradle-wrapper.properties', []),
            ]),
          ]),
          FileTreeNode('.gitignore', false, 'Ide editor/.gitignore', []),
          FileTreeNode('app_config.json', false, 'Ide editor/app_config.json', []),
          FileTreeNode('build.gradle', false, 'Ide editor/build.gradle', []),
          FileTreeNode('gradle.properties', false, 'Ide editor/gradle.properties', []),
          FileTreeNode('gradlew', false, 'Ide editor/gradlew', []),
          FileTreeNode('gradlew.bat', false, 'Ide editor/gradlew.bat', []),
          FileTreeNode('libraries.json', false, 'Ide editor/libraries.json', []),
          FileTreeNode('local.properties', false, 'Ide editor/local.properties', []),
          FileTreeNode('proguard-rules.pro', false, 'Ide editor/proguard-rules.pro', []),
          FileTreeNode('repositories.json', false, 'Ide editor/repositories.json', []),
          FileTreeNode('settings.gradle', false, 'Ide editor/settings.gradle', []),
          FileTreeNode('settings.json', false, 'Ide editor/settings.json', []),
        ],
      ),
    ];
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

  String _getFileContent(String fileName) {
    if (fileName == 'FileTreeActivity.java') {
      return '''package com.ide.editor;

import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;''';
    } else if (fileName.endsWith('.java')) {
      return '''package com.ide.editor;

import android.os.Bundle;
import android.view.View;

public class ${fileName.replaceAll('.java', '')} {
    
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
        versionCode 1
        versionName "1.0"
    }
    
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
}''';
    } else if (fileName.endsWith('.json')) {
      return '''{
  "name": "Ide editor",
  "version": "1.0.0",
  "description": "A mobile IDE editor",
  "main": "index.js"
}''';
    } else if (fileName.endsWith('.xml')) {
      return '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ide.editor">

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name">
        
    </application>

</manifest>''';
    }
    return '// ${fileName}\n\n';
  }

  void _closeTab(int index) {
    setState(() {
      _openTabs.removeAt(index);
      if (_selectedTabIndex >= _openTabs.length) {
        _selectedTabIndex = _openTabs.length - 1;
      }
      if (_openTabs.isEmpty) {
        _codeController.clear();
      } else if (_selectedTabIndex >= 0) {
        _codeController.text = _openTabs[_selectedTabIndex].content;
      }
      _tabController = TabController(length: _openTabs.length, vsync: this);
      if (_selectedTabIndex >= 0 && _openTabs.isNotEmpty) {
        _tabController.index = _selectedTabIndex;
      }
    });
  }

  void _refreshProject() {
    setState(() {
      _isIndexing = true;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isIndexing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project refreshed!'),
          backgroundColor: Colors.blue,
        ),
      );
    });
  }

  void _closeProject() {
    setState(() {
      _currentProject = '';
      _currentProjectPath = '';
      _fileTree.clear();
      _openTabs.clear();
      _codeController.clear();
      _selectedTabIndex = -1;
      _expandedFolders.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project closed'),
        backgroundColor: Colors.orange,
      ),
    );
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
            onPressed: () => _buildProject('debug APK'),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _openLocalFolder,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
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
                    indicatorColor: Colors.orange,
                    indicatorWeight: 3,
                    onTap: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                        _codeController.text = _openTabs[index].content;
                      });
                    },
                    tabs: _openTabs.asMap().entries.map((entry) {
                      int idx = entry.key;
                      EditorTab tab = entry.value;
                      return Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
        