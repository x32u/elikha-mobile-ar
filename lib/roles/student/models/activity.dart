class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.category,
    required this.materials,
    required this.dueDate,
    required this.completed,
  });

  final int id;
  final String title;
  final String description;
  final String fullDescription;
  final String category;
  final List<String> materials;
  final DateTime dueDate;
  final bool completed;
}
