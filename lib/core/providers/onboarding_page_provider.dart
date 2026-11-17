import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingPageProvider = NotifierProvider<OnboardingPageController, int>(
  OnboardingPageController.new,
);

class OnboardingPageController extends Notifier<int> {
  static const int pageCount = 3;

  @override
  int build() {
    return 0;
  }

  void setPage(int page) {
    if (page < 0 || page >= pageCount) {
      return;
    }

    state = page;
  }
}
