/// Represents a single course/subject shown on the dashboard.
class SubjectModel {
  const SubjectModel({
    required this.name,
    required this.description,
    required this.classTiming,
    required this.scheduleInfo,
    required this.instructor,
  });

  final String name;
  final String description;
  final String classTiming;
  final String scheduleInfo;
  final String instructor;
}

/// Static catalogue of subjects. In a production app this would come
/// from a remote API or local database instead of being hard-coded.
const List<SubjectModel> kSubjects = [
  SubjectModel(
    name: 'Mobile App Development',
    description:
        'Hands-on course covering cross-platform mobile development with '
        'Flutter. Topics include widgets, state management, navigation, '
        'form handling and connecting apps to backend services.',
    classTiming: 'Mon & Wed · 09:00 AM – 10:30 AM',
    scheduleInfo: 'Lab Block B, Room 204 · 3 credit hours',
    instructor: 'Dr. Ayesha Khan',
  ),
  SubjectModel(
    name: 'Software Re-engineering',
    description:
        'Explores techniques for analysing, restructuring and modernising '
        'legacy software systems. Covers reverse engineering, refactoring '
        'strategies and migration to maintainable architectures.',
    classTiming: 'Tue & Thu · 11:00 AM – 12:30 PM',
    scheduleInfo: 'Main Building, Room 110 · 3 credit hours',
    instructor: 'Prof. Bilal Ahmed',
  ),
  SubjectModel(
    name: 'Management Information Systems (MIS)',
    description:
        'Studies how organisations use information systems to support '
        'decision-making and operations. Covers business processes, '
        'databases, ERP systems and IT strategy.',
    classTiming: 'Fri · 02:00 PM – 05:00 PM',
    scheduleInfo: 'Business Faculty, Room 301 · 3 credit hours',
    instructor: 'Dr. Sana Malik',
  ),
];
