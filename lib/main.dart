import 'package:flutter/material.dart';

void main() => runApp(MyApp());

// 🔹 MAIN APP START
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ✅ ROUTES START (for navigation to multiple screens)
      routes: {
        '/': (context) => const TodoHomePage(),
        '/about': (context) => const AboutPage(),
        '/settings': (context) => const SettingsPage(),
      },
      // ✅ ROUTES END
    );
  }
}
// 🔹 MAIN APP END


// 🔹 TODO HOME PAGE START
class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  // 🔸 CONTROLLERS & VARIABLES START
  final TextEditingController _controller = TextEditingController();
  final List<String> _todos = [];
  int _selectedIndex = 0; // for Bottom Navigation
  // 🔸 CONTROLLERS & VARIABLES END


  // ✅ FUNCTION: Add Todo START
  void _addTodo() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _todos.add(_controller.text);
      _controller.clear();
    });
  }
  // ✅ FUNCTION: Add Todo END


  // ✅ FUNCTION: Remove Todo START
  void _removeTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }
  // ✅ FUNCTION: Remove Todo END


  // ✅ FUNCTION: Show Bottom Sheet START
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Add Task (Bottom Sheet)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: 'Enter a task'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addTodo();
                  Navigator.pop(context); // close bottom sheet
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }
  // ✅ FUNCTION: Show Bottom Sheet END


  // ✅ FUNCTION: Bottom Navigation Tap START
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completed Tasks Screen')),
      );
    }
  }
  // ✅ FUNCTION: Bottom Navigation Tap END


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ✅ TOOLBAR (APPBAR) START
      appBar: AppBar(
        title: const Text('Todo App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // 🔹 Navigate to About Page
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
      // ✅ TOOLBAR (APPBAR) END


      // ✅ DRAWER (SIDE MENU) START
      Drawer(
  child: Container(
    color: Colors.blue, // 👈 ek hi color poore drawer ke liye
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue, // 👈 same color rakho
          ),
          child: Text(
            'Navigation Menu',
            style: TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          leading: Icon(Icons.home, color: Colors.white),
          title: Text('Home', style: TextStyle(color: Colors.white)),
        ),
        ListTile(
          leading: Icon(Icons.settings, color: Colors.white),
          title: Text('Settings', style: TextStyle(color: Colors.white)),
        ),
        ListTile(
          leading: Icon(Icons.info, color: Colors.white),
          title: Text('About', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  ),
)
      // ✅ DRAWER (SIDE MENU) END


      // ✅ BODY (MAIN CONTENT AREA) START
      body: Column(
        children: [
          // 🔹 Input Field + Add Button Row START
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Enter a new task'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          // 🔹 Input Field + Add Button Row END

          // 🔹 Todo ListView START
          Expanded(
            child: _todos.isEmpty
                ? const Center(child: Text('No tasks added yet!'))
                : ListView.builder(
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_todos[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeTodo(index),
                        ),
                      );
                    },
                  ),
          ),
          // 🔹 Todo ListView END
        ],
      ),
      // ✅ BODY (MAIN CONTENT AREA) END


      // ✅ FLOATING ACTION BUTTON START
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet, // Opens Bottom Sheet
        child: const Icon(Icons.add),
      ),
      // ✅ FLOATING ACTION BUTTON END


      // ✅ BOTTOM NAVIGATION BAR START
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Tasks'), // Tab 0
          BottomNavigationBarItem(
              icon: Icon(Icons.done_all), label: 'Completed'), // Tab 1
        ],
        onTap: _onTabTapped,
      ),
      // ✅ BOTTOM NAVIGATION BAR END
    );
  }
}
// 🔹 TODO HOME PAGE END



// 🔹 ABOUT PAGE START
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ APPBAR START
      appBar: AppBar(title: const Text('About App')),
      // ✅ APPBAR END

      // ✅ BODY START
      body: const Center(
        child: Text(
          'This is a Todo App example.\nDeveloped in Flutter.',
          textAlign: TextAlign.center,
        ),
      ),
      // ✅ BODY END
    );
  }
}
// 🔹 ABOUT PAGE END



// 🔹 SETTINGS PAGE START
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ APPBAR START
      appBar: AppBar(title: const Text('Settings')),
      // ✅ APPBAR END

      // ✅ BODY START
      body: const Center(
        child: Text('Settings Screen (Under Development)'),
      ),
      // ✅ BODY END
    );
  }
}
// 🔹 SETTINGS PAGE END