import 'package:flutter/foundation.dart';

class AdUnitIds {
  static String get homeBannerAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/8212647184'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get groupTransportAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/4521617750'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get groupTransporterAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/5584236221'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get itemTransportAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/9870965592'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get itemTransporterAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/7973536356'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get privateCommuterAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/1549622446'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get privateDriverAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/7666414596'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get publicCommuterAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/9569930308'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get publicDriverAd => kReleaseMode
      ? 'ca-app-pub-1273948640342808/4738058411'
      : 'ca-app-pub-3940256099942544/6300978111';
}
