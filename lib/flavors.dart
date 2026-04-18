enum Flavor {
  dev,
  beta,
  rel,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return 'DioHub - Dev';
      case Flavor.beta:
        return 'DioHub - Beta';
      case Flavor.rel:
        return 'DioHub';
    }
  }
}
