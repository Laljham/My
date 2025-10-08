import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class GitHubService {
  static const String token = "YOUR_PERSONAL_ACCESS_TOKEN"; // 🔑 Apna token yahan daalein
  static const String owner = "Laljham";
  static const String repo = "My";
  static const String path = "Hello-world.zip"; // Repo me file path
  static const String commitMessage = "Update Hello-world.zip from app";

  static Future<void> pushZipFromAssets() async {
    try {
      // 1️⃣ Load ZIP file from assets
      ByteData data = await rootBundle.load('assets/Hello-world.zip');
      Uint8List bytes = data.buffer.asUint8List();
      String encodedContent = base64Encode(bytes);

      // 2️⃣ Check if file exists to get SHA
      Uri getUrl = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
      var getResponse = await http.get(
        getUrl,
        headers: {'Authorization': 'token $token'},
      );

      String? sha;
      if (getResponse.statusCode == 200) {
        var json = jsonDecode(getResponse.body);
        sha = json['sha'];
        print("🔹 Existing file SHA: $sha");
      }

      // 3️⃣ Prepare request body
      Map<String, dynamic> body = {
        "message": commitMessage,
        "content": encodedContent,
      };
      if (sha != null) {
        body["sha"] = sha;
      }

      // 4️⃣ PUT request to update/create file
      var putResponse = await http.put(
        getUrl,
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github+json',
        },
        body: jsonEncode(body),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        print("✅ File pushed successfully!");
      } else {
        print("❌ Failed to push file: ${putResponse.body}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }
}