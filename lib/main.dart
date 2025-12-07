import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorHome(),
    );
  }
}

class CalculatorHome extends StatefulWidget {
  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String input = "";
  String result = "0";

  final List<String> buttons = [
    "C", "⌫", "%", "/",
    "7", "8", "9", "*",
    "4", "5", "6", "-",
    "1", "2", "3", "+",
    "00", "0", ".", "=",
  ];

  /// Open your URL
  Future<void> openURL() async {
    final url = Uri.parse("https://shashi.zya.me/");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not launch $url";
    }
  }

  void buttonPressed(String value) {
    setState(() {
      if (value == "C") {
        input = "";
        result = "0";
      } else if (value == "⌫") {
        if (input.isNotEmpty) input = input.substring(0, input.length - 1);
      } else if (value == "=") {
        try {
          result = calculate(input).toString();
        } catch (e) {
          result = "Error";
        }
      } else {
        input += value;
      }
    });
  }

  double calculate(String expr) {
    List<String> tokens = expr.split(RegExp(r'([+\-*/%])')).toList();
    List<String> ops = expr.split(RegExp(r'[0-9.]')).where((e) => e != "").toList();

    double total = double.parse(tokens[0]);

    for (int i = 1; i < tokens.length; i++) {
      if (tokens[i].trim().isEmpty) continue;
      double number = double.parse(tokens[i]);
      String op = ops[i - 1];

      switch (op) {
        case '+':
          total += number;
          break;
        case '-':
          total -= number;
          break;
        case '*':
          total *= number;
          break;
        case '/':
          total /= number;
          break;
        case '%':
          total %= number;
          break;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Calculator"),
        centerTitle: true,
      ),

      body: Column(
        children: [
          /// Your Website Banner
          InkWell(
            onTap: openURL,
            child: Container(
              width: double.infinity,
              color: Colors.deepPurple,
              padding: const EdgeInsets.all(12),
              child: const Text(
                "Visit: https://shashi.zya.me/",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // Display
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    input,
                    style: const TextStyle(color: Colors.white70, fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result,
                    style: const TextStyle(color: Colors.white, fontSize: 48),
                  ),
                ],
              ),
            ),
          ),

          // Buttons Grid
          Expanded(
            flex: 2,
            child: GridView.builder(
              itemCount: buttons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOperator(buttons[index])
                          ? Colors.deepPurple
                          : Colors.grey[850],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => buttonPressed(buttons[index]),
                    child: Text(
                      buttons[index],
                      style: const TextStyle(color: Colors.white, fontSize: 22),
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

  bool isOperator(String x) {
    return (x == "/" || x == "*" || x == "-" || x == "+" || x == "%");
  }
}