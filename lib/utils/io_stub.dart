// Заглушка для веб-платформы, чтобы избежать ошибок компиляции
class File {
  final String path;
  File(this.path);
  
  Future<void> writeAsString(String content) async {
    // На вебе ничего не делаем, так как используем другие методы
  }
  
  Future<String> readAsString() async {
    return '';
  }
}
