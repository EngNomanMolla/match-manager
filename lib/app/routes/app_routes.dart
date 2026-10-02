import 'package:get/get.dart';
import '../views/splash/splash_view.dart';
import '../views/main/main_nav_view.dart';
import '../views/board/create_board_view.dart';
import '../views/board/board_detail_view.dart';
import '../views/board/join_board_view.dart';
import '../views/profile/profile_view.dart';

class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const createBoard = '/create-board';
  static const boardDetail = '/board-detail';
  static const joinBoard = '/join-board';
  static const profile = '/profile';

  static final pages = [
    GetPage(
      name: splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: home,
      page: () => const MainNavView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: createBoard,
      page: () => const CreateBoardView(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: boardDetail,
      page: () => const BoardDetailView(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: joinBoard,
      page: () => const JoinBoardView(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: profile,
      page: () => const ProfileView(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
