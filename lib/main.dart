import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TodoHome(),
    );
  }
}

class TodoHome extends StatefulWidget {
  @override
  State<TodoHome> createState() => _TodoHomeState();
}

class _TodoHomeState extends State<TodoHome> {
  List<Map<String, dynamic>> todos = [];
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  /// Load Todos
  Future<void> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString("todos");

    if (saved != null) {
      final List decoded = json.decode(saved);
      setState(() {
        todos = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  /// Save Todos
  Future<void> saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("todos", json.encode(todos));
  }

  /// Add Task
  void addTodo() {
    if (controller.text.trim().isEmpty) return;

    setState(() {
      todos.add({"task": controller.text.trim(), "done": false});
    });

    controller.clear();
    saveTodos();
  }

  /// Toggle Complete
  void toggleDone(int index) {
    setState(() {
      todos[index]["done"] = !todos[index]["done"];
    });
    saveTodos();
  }

  /// Delete Task
  void deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
    });
    saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Todo App"),
        backgroundColor: Colors.deepPurple,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        onPressed: addTodo,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add a task...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: todos.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks yet!",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final task = todos[index];

                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          leading: Checkbox(
                            value: task["done"],
                            onChanged: (_) => toggleDone(index),
                            activeColor: Colors.deepPurple,
                          ),
                          title: Text(
                            task["task"],
                            style: TextStyle(
                              color: Colors.white,
                              decoration: task["done"]
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          trailing: IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => deleteTodo(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}