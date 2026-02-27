class HomeItem {
  const HomeItem({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  factory HomeItem.fromJson(Map<String, dynamic> json) => HomeItem(
        title: json['title'] as String? ?? 'Untitled',
        subtitle: json['subtitle'] as String? ?? 'No description',
      );
}

