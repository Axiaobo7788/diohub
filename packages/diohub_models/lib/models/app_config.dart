/// App capability level, ordered by capability.
enum AppConfig implements Comparable<AppConfig> {
  free,
  pro;

  bool get isPro => index >= AppConfig.pro.index;

  @override
  int compareTo(AppConfig other) => index.compareTo(other.index);
}
