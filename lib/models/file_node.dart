class FileNode {
  String name;
  String fullPath;
  bool isExpanded;
  bool isFile;
  List<FileNode> children;
  String? content;
  
  FileNode({
    required this.name,
    required this.fullPath,
    required this.isFile,
    this.isExpanded = false,
    this.children = const [],
    this.content,
  });
}