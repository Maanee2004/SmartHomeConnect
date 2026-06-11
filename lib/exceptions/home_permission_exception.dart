class HomePermissionDeniedException implements Exception {
  const HomePermissionDeniedException([
    this.message =
        'Action réservée aux administrateurs. Contactez votre admin.',
  ]);

  final String message;

  @override
  String toString() => message;
}
