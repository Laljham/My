class FileNode {
  String name;
  String fullPath;
  bool isExpanded;
  bool isFile;
  List<FileNode> children;
  String? content; // File ka content store karne ke liye
  
  FileNode({
    required this.name,
    required this.fullPath,
    required this.isFile,
    this.isExpanded = false,
    this.children = const [],
    this.content,
  });
  
  // Helper method to find a node by path
  FileNode? findByPath(String path) {
    if (fullPath == path) return this;
    
    for (var child in children) {
      var found = child.findByPath(path);
      if (found != null) return found;
    }
    return null;
  }
}