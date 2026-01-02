class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final String? next;
  final String? previous;

  PaginatedResponse({
    required this.data,
    required this.total,
    this.next,
    this.previous,
  });
}
