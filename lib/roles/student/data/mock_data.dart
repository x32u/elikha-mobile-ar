import '../models/activity.dart';
import '../models/artwork.dart';
import '../models/notification_item.dart';

class MockData {
  static DateTime _daysFromNow(int days) =>
      DateTime.now().add(Duration(days: days));

  static List<Artwork> artworks() {
    return const [
      Artwork(id: 1, title: 'Artwork 1'),
      Artwork(id: 2, title: 'Artwork 2'),
      Artwork(id: 3, title: 'Artwork 3'),
      Artwork(id: 4, title: 'Artwork 4'),
    ];
  }

  static List<Activity> activities() {
    return [
      Activity(
        id: 1,
        title: 'Origami Dog',
        description: 'Fold a paper dog',
        fullDescription:
            'Learn to fold paper into fun animal shapes. This project teaches basic origami techniques.',
        category: 'Origami Animals',
        materials: const ['Origami Paper', 'Scissors', 'Markers'],
        dueDate: _daysFromNow(2),
        completed: false,
      ),
      Activity(
        id: 2,
        title: 'Clay Sculptures',
        description: 'Create clay art pieces',
        fullDescription:
            'Create amazing 3D sculptures using air-dry clay. Learn shaping and texturing techniques.',
        category: 'Sculpture Basics',
        materials: const ['Air-dry Clay', 'Sculpting Tools', 'Water'],
        dueDate: _daysFromNow(5),
        completed: false,
      ),
      Activity(
        id: 3,
        title: 'Paper Mache Masks',
        description: 'Design decorative masks',
        fullDescription:
            'Design and create beautiful decorative masks using paper mache techniques.',
        category: 'Mask Making',
        materials: const ['Newspaper', 'Paste', 'Paint', 'Brushes'],
        dueDate: _daysFromNow(7),
        completed: false,
      ),
      Activity(
        id: 4,
        title: 'Watercolor Painting',
        description: 'Create watercolor artwork',
        fullDescription:
            'Explore watercolor painting techniques and create beautiful artworks.',
        category: 'Painting',
        materials: const ['Watercolor Set', 'Brushes', 'Paper'],
        dueDate: _daysFromNow(-1),
        completed: false,
      ),
      Activity(
        id: 5,
        title: 'Collage Project',
        description: 'Make a magazine collage',
        fullDescription:
            'Create an artistic collage using magazine cutouts and other materials.',
        category: 'Mixed Media',
        materials: const ['Magazines', 'Scissors', 'Glue', 'Paper'],
        dueDate: _daysFromNow(-3),
        completed: true,
      ),
      Activity(
        id: 6,
        title: 'Sketch Study',
        description: 'Practice sketching techniques',
        fullDescription:
            'Practice various sketching techniques to improve your drawing skills.',
        category: 'Drawing',
        materials: const ['Sketchbook', 'Pencils', 'Eraser'],
        dueDate: _daysFromNow(-7),
        completed: true,
      ),
    ];
  }

  static List<NotificationItem> notifications() {
    return const [
      NotificationItem(
        id: 1,
        title: 'New activity posted: Watercolor Basics',
        time: '2m ago',
        unread: true,
      ),
      NotificationItem(
        id: 2,
        title: 'Your project was graded by your teacher',
        time: '5h ago',
        unread: false,
      ),
      NotificationItem(
        id: 3,
        title: 'You have a due Paper art project',
        time: 'Yesterday',
        unread: false,
      ),
    ];
  }
}
