import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/*──────────────────────────────
 🟦 MAIN APP START
──────────────────────────────*/
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Editor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const CodeEditorHomePage(),
    );
  }
}
/*──────────────────────────────
 🟦 MAIN APP END
──────────────────────────────*/



/*──────────────────────────────
 🟩 HOME PAGE (MAIN SCREEN) START
──────────────────────────────*/
class CodeEditorHomePage extends StatefulWidget {
  const CodeEditorHomePage({super.key});

  @override
  State<CodeEditorHomePage> createState() => _CodeEditorHomePageState();
}

class _CodeEditorHomePageState extends State<CodeEditorHomePage> {
  // 🔸 VARIABLES START
  final TextEditingController _codeController = TextEditingController(
    text: "// Write your code here...\n\nvoid main() {\n  print('Hello Flutter!');\n}",
  );
  bool isExpanded = false; // bottom sheet expand/collapse control
  // 🔸 VARIABLES END

  // 🔹 DRAWER FILE LIST (Fake structure for now)
  final List<String> files = [
    "main.dart",
    "home_page.dart",
    "editor.dart",
    "theme.dart",
    "utils/helpers.dart"
  ];

  /*──────────────────────────────
   🧭 TOOLBAR (APPBAR) START
  ──────────────────────────────*/
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Flutter Code Editor"),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: "Save File",
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File Saved Successfully!")),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
      ],
    );
  }
  /*──────────────────────────────
   🧭 TOOLBAR (APPBAR) END
  ──────────────────────────────*/


  /*──────────────────────────────
   📁 DRAWER (FILE NAVIGATION) START
  ──────────────────────────────*/
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Text("📂 Project Files",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          for (var file in files)
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(file),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Opened: $file")),
                );
              },
            ),
        ],
      ),
    );
  }
  /*──────────────────────────────
   📁 DRAWER (FILE NAVIGATION) END
  ──────────────────────────────*/


  /*──────────────────────────────
   🧾 MAIN EDITOR AREA START (Center 70%)
  ──────────────────────────────*/
  Widget _buildEditorArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: TextField(
        controller: _codeController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }
  /*──────────────────────────────
   🧾 MAIN EDITOR AREA END
  ──────────────────────────────*/


  /*──────────────────────────────
   🧩 PERSISTENT BOTTOM SHEET START
   - 10% visible always
   - swipe to expand
  ──────────────────────────────*/
  Widget _buildBottomSheet() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isExpanded
          ? MediaQuery.of(context).size.height * 0.4
          : MediaQuery.of(context).size.height * 0.1,
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(blurRadius: 6, color: Colors.black26),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text("Console Output",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: const Text(
                "Build running...\nNo errors found ✅",
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /*──────────────────────────────
   🧩 PERSISTENT BOTTOM SHEET END
  ──────────────────────────────*/


  /*──────────────────────────────
   ⚙️ BUILD METHOD START
  ──────────────────────────────*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(), // Toolbar
      drawer: _buildDrawer(), // Side menu (file tree)
      body: Stack(
        children: [
          // Main editor (70–80%)
          Positioned.fill(
            child: _buildEditorArea(),
          ),

          // Bottom sheet fixed
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(),
          ),
        ],
      ),
    );
  }
  /*──────────────────────────────
   ⚙️ BUILD METHOD END
  ──────────────────────────────*/
}
/*──────────────────────────────
 🟩 HOME PAGE (MAIN SCREEN) END
──────────────────────────────*/