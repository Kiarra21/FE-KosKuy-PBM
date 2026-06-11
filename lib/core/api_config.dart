class ApiConfig {
  static const rootUrl = 'https://apikoskuy.kiarrapro.id';
  static const baseUrl = '$rootUrl/api';

  static String storageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) return '$rootUrl$path';
    return '$rootUrl/storage/$path';
  }
}
