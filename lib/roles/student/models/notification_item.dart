class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.time,
    required this.unread,
  });

  final int id;
  final String title;
  final String time;
  final bool unread;

  NotificationItem copyWith({bool? unread}) {
    return NotificationItem(
      id: id,
      title: title,
      time: time,
      unread: unread ?? this.unread,
    );
  }
}
