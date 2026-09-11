final class AppNotice {
  const AppNotice({
    required this.id,
    required this.message,
    required this.isFavorite,
  });

  final int id;
  final String message;
  final bool isFavorite;
}
