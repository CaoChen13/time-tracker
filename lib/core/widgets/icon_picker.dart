import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';
import 'pressable.dart';

/// SVG 图标分类配置
const svgIconCategories = <String, String>{
  '工作': 'work',
  '学习': 'study',
  '饮食': 'eat',
  '睡眠': 'sleep',
  '运动': 'exercise',
  '娱乐': 'entertainment',
  '交通': 'transportation',
  '社交': 'communication',
  '购物': 'shopingIcon',
};

/// 自定义图标目录名
const _customIconsDir = 'custom_icons';

/// 获取自定义图标目录
Future<Directory> _getCustomIconsDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(appDir.path, _customIconsDir));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// 获取所有自定义图标路径
Future<List<String>> getCustomIcons() async {
  final dir = await _getCustomIconsDirectory();
  final files = await dir.list().toList();
  return files.whereType<File>().map((f) => f.path).toList()..sort((a, b) => b.compareTo(a));
}

/// 保存自定义图标
Future<String> saveCustomIcon(File sourceFile) async {
  final dir = await _getCustomIconsDirectory();
  final ext = p.extension(sourceFile.path);
  final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
  final destPath = p.join(dir.path, fileName);
  await sourceFile.copy(destPath);
  return 'custom:$destPath';
}

/// 删除自定义图标
Future<void> deleteCustomIcon(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

/// 判断是否是自定义图标
bool isCustomIcon(String? icon) => icon != null && icon.startsWith('custom:');

/// 判断是否是 SVG 图标
bool isSvgIcon(String? icon) => icon != null && icon.startsWith('svg:');

/// 获取自定义图标的文件路径
String? getCustomIconPath(String? icon) {
  if (icon == null || !icon.startsWith('custom:')) return null;
  return icon.substring(7);
}

/// 获取 SVG 图标的 asset 路径
String? getSvgIconPath(String? icon) {
  if (icon == null || !icon.startsWith('svg:')) return null;
  return icon.substring(4);
}

/// 统一的图标显示 Widget
class IconDisplay extends StatelessWidget {
  final String? icon;
  final double size;
  final Color? color;

  const IconDisplay({super.key, this.icon, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    if (icon == null || icon!.isEmpty) return _buildDefault();

    if (isSvgIcon(icon)) {
      final path = getSvgIconPath(icon);
      if (path != null) {
        return SvgPicture.asset(
          path,
          width: size,
          height: size,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          placeholderBuilder: (_) => _buildDefault(),
        );
      }
    }

    if (isCustomIcon(icon)) {
      final path = getCustomIconPath(icon);
      if (path != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.2),
          child: Image.file(File(path), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefault()),
        );
      }
    }

    // Emoji (兼容旧数据)
    return Text(icon!, style: TextStyle(fontSize: size * 0.85));
  }

  Widget _buildDefault() => Icon(Icons.category_outlined, size: size, color: color ?? Colors.grey);
}

/// 兼容旧代码
IconData getIconByName(String? name) => Icons.category_outlined;


/// 完整的图标列表
const _allSvgIcons = <String, List<String>>{
  'work': [
    'assets/icons/work/icons8-clipboard-50.svg',
    'assets/icons/work/icons8-construction-trowel-50.svg',
    'assets/icons/work/icons8-coworking-50.svg',
    'assets/icons/work/icons8-hair-protection-50.svg',
    'assets/icons/work/icons8-hammer-50.svg',
    'assets/icons/work/icons8-new-job-50.svg',
    'assets/icons/work/icons8-open-end-wrench-50.svg',
    'assets/icons/work/icons8-trowel-50.svg',
    'assets/icons/work/icons8-wear-welding-mask-50.svg',
    'assets/icons/work/icons8-work-50-2.svg',
    'assets/icons/work/icons8-work-50-3.svg',
    'assets/icons/work/icons8-work-50-4.svg',
    'assets/icons/work/icons8-work-50-5.svg',
    'assets/icons/work/icons8-work-50.svg',
    'assets/icons/work/icons8-backend-development-50.svg',
    'assets/icons/work/icons8-binary-file-50.svg',
    'assets/icons/work/icons8-black-tie-50.svg',
    'assets/icons/work/icons8-c-plus-plus-50.svg',
    'assets/icons/work/icons8-code-50-2.svg',
    'assets/icons/work/icons8-code-50.svg',
    'assets/icons/work/icons8-code-fork-50.svg',
    'assets/icons/work/icons8-cursor-ai-50.svg',
    'assets/icons/work/icons8-developer-50.svg',
    'assets/icons/work/icons8-github-50.svg',
    'assets/icons/work/icons8-html-filetype-50.svg',
    'assets/icons/work/icons8-java-50.svg',
    'assets/icons/work/icons8-javascript-50.svg',
    'assets/icons/work/icons8-rest-api-50.svg',
    'assets/icons/work/icons8-scan-nfc-tag-50.svg',
    'assets/icons/work/icons8-visual-studio-code-2019-50.svg',
  ],
  'study': [
    'assets/icons/study/icons8-add-book-50.svg',
    'assets/icons/study/icons8-adverb-50.svg',
    'assets/icons/study/icons8-audio-book-50.svg',
    'assets/icons/study/icons8-book-and-pencil-50.svg',
    'assets/icons/study/icons8-book-shelf-50.svg',
    'assets/icons/study/icons8-book-stack-50.svg',
    'assets/icons/study/icons8-books-50-2.svg',
    'assets/icons/study/icons8-books-50.svg',
    'assets/icons/study/icons8-borrow-book-50.svg',
    'assets/icons/study/icons8-calculate-50.svg',
    'assets/icons/study/icons8-camara-education-50.svg',
    'assets/icons/study/icons8-class-50.svg',
    'assets/icons/study/icons8-classroom-50.svg',
    'assets/icons/study/icons8-confusion-50.svg',
    'assets/icons/study/icons8-congruent-symbol-50.svg',
    'assets/icons/study/icons8-curriculum-50.svg',
    'assets/icons/study/icons8-dictionary-50.svg',
    'assets/icons/study/icons8-e-learning-50.svg',
    'assets/icons/study/icons8-earth-globe-50.svg',
    'assets/icons/study/icons8-elective-50.svg',
    'assets/icons/study/icons8-equation-50.svg',
    'assets/icons/study/icons8-erase-from-the-board-50.svg',
    'assets/icons/study/icons8-ereader-50.svg',
    'assets/icons/study/icons8-exam-50.svg',
    'assets/icons/study/icons8-google-classroom-50.svg',
    'assets/icons/study/icons8-grammar-50.svg',
    'assets/icons/study/icons8-greater-50.svg',
    'assets/icons/study/icons8-hand-with-pen-50.svg',
    'assets/icons/study/icons8-homework-50.svg',
    'assets/icons/study/icons8-informatics-50.svg',
    'assets/icons/study/icons8-interactive-whiteboard-50.svg',
    'assets/icons/study/icons8-khan-academy-50.svg',
    'assets/icons/study/icons8-knowledge-sharing-50.svg',
    'assets/icons/study/icons8-learn-information-50.svg',
    'assets/icons/study/icons8-learning-50.svg',
    'assets/icons/study/icons8-library-50.svg',
    'assets/icons/study/icons8-library-building-50.svg',
    'assets/icons/study/icons8-mba-50.svg',
    'assets/icons/study/icons8-moodle-50.svg',
    'assets/icons/study/icons8-mu-50.svg',
    'assets/icons/study/icons8-noun-50.svg',
    'assets/icons/study/icons8-quill-with-ink-50.svg',
    'assets/icons/study/icons8-read-50.svg',
    'assets/icons/study/icons8-reference-50.svg',
    'assets/icons/study/icons8-remove-book-50.svg',
    'assets/icons/study/icons8-return-book-50.svg',
    'assets/icons/study/icons8-school-50.svg',
    'assets/icons/study/icons8-schoology-50.svg',
    'assets/icons/study/icons8-scientist-man-skin-type-3-50.svg',
    'assets/icons/study/icons8-spiral-bound-booklet-50.svg',
    'assets/icons/study/icons8-square-root-50.svg',
    'assets/icons/study/icons8-student-center-50.svg',
    'assets/icons/study/icons8-study-50-2.svg',
    'assets/icons/study/icons8-study-50-3.svg',
    'assets/icons/study/icons8-study-50-4.svg',
    'assets/icons/study/icons8-study-50-5.svg',
    'assets/icons/study/icons8-study-50.svg',
    'assets/icons/study/icons8-study-bunny-50.svg',
    'assets/icons/study/icons8-translation-50.svg',
    'assets/icons/study/icons8-under-prepositions-50.svg',
    'assets/icons/study/icons8-view-50.svg',
  ],
  'eat': [
    'assets/icons/eat/icons8-beef-50.svg',
    'assets/icons/eat/icons8-birthday-cake-50.svg',
    'assets/icons/eat/icons8-bread-crumbs-50.svg',
    'assets/icons/eat/icons8-carrot-50.svg',
    'assets/icons/eat/icons8-cheese-50.svg',
    'assets/icons/eat/icons8-cherry-50.svg',
    'assets/icons/eat/icons8-chicken-and-waffle-50.svg',
    'assets/icons/eat/icons8-cinnamon-roll-50.svg',
    'assets/icons/eat/icons8-cookie-50.svg',
    'assets/icons/eat/icons8-cookies-50.svg',
    'assets/icons/eat/icons8-croissant-50.svg',
    'assets/icons/eat/icons8-dog-bowl-50.svg',
    'assets/icons/eat/icons8-doughnut-50.svg',
    'assets/icons/eat/icons8-eat-50-2.svg',
    'assets/icons/eat/icons8-eat-50-3.svg',
    'assets/icons/eat/icons8-eat-50-4.svg',
    'assets/icons/eat/icons8-eat-50.svg',
    'assets/icons/eat/icons8-food-50.svg',
    'assets/icons/eat/icons8-food-and-wine-50.svg',
    'assets/icons/eat/icons8-food-donor-50.svg',
    'assets/icons/eat/icons8-french-fries-50.svg',
    'assets/icons/eat/icons8-hamburger-50.svg',
    'assets/icons/eat/icons8-hot-dog-50.svg',
    'assets/icons/eat/icons8-kebab-50.svg',
    'assets/icons/eat/icons8-lasagna-50.svg',
    'assets/icons/eat/icons8-lunchbox-50.svg',
    'assets/icons/eat/icons8-mushroom-50.svg',
    'assets/icons/eat/icons8-pear-50.svg',
    'assets/icons/eat/icons8-pizza-50.svg',
    'assets/icons/eat/icons8-plate-50.svg',
    'assets/icons/eat/icons8-popcorn-50.svg',
    'assets/icons/eat/icons8-rice-bowl-50.svg',
    'assets/icons/eat/icons8-sandwich-50.svg',
    'assets/icons/eat/icons8-soup-plate-50.svg',
    'assets/icons/eat/icons8-spaghetti-50.svg',
    'assets/icons/eat/icons8-steak-50.svg',
    'assets/icons/eat/icons8-taco-50.svg',
    'assets/icons/eat/icons8-vegetarian-food-50.svg',
  ],
  'sleep': [
    'assets/icons/sleep/icons8-bed-50.svg',
    'assets/icons/sleep/icons8-sleep-50-2.svg',
    'assets/icons/sleep/icons8-sleep-50.svg',
    'assets/icons/sleep/icons8-sleeping-homeless-50.svg',
  ],
  'exercise': [
    'assets/icons/exercise/icons8-apple-fitness-50.svg',
    'assets/icons/exercise/icons8-badminton-player-50.svg',
    'assets/icons/exercise/icons8-ballerina-50.svg',
    'assets/icons/exercise/icons8-barbells-50.svg',
    'assets/icons/exercise/icons8-bench-press-skin-type-1-50.svg',
    'assets/icons/exercise/icons8-breath-50.svg',
    'assets/icons/exercise/icons8-climbing-wall-50.svg',
    'assets/icons/exercise/icons8-dancing-50.svg',
    'assets/icons/exercise/icons8-deadlift-50.svg',
    'assets/icons/exercise/icons8-dumbbell-50.svg',
    'assets/icons/exercise/icons8-exercise-50-2.svg',
    'assets/icons/exercise/icons8-exercise-50-3.svg',
    'assets/icons/exercise/icons8-exercise-50-4.svg',
    'assets/icons/exercise/icons8-exercise-50-5.svg',
    'assets/icons/exercise/icons8-exercise-50-6.svg',
    'assets/icons/exercise/icons8-exercise-50-7.svg',
    'assets/icons/exercise/icons8-exercise-50.svg',
    'assets/icons/exercise/icons8-gym-50.svg',
    'assets/icons/exercise/icons8-gym-bench-50.svg',
    'assets/icons/exercise/icons8-home-workout-50.svg',
    'assets/icons/exercise/icons8-jump-rope-50.svg',
    'assets/icons/exercise/icons8-knock-down-50.svg',
    'assets/icons/exercise/icons8-learning-50.svg',
    'assets/icons/exercise/icons8-mma-fighter-glove-50.svg',
    'assets/icons/exercise/icons8-open-copybook-50.svg',
    'assets/icons/exercise/icons8-parkour-50.svg',
    'assets/icons/exercise/icons8-pilates-50.svg',
    'assets/icons/exercise/icons8-pullups-50.svg',
    'assets/icons/exercise/icons8-punching-bag-50.svg',
    'assets/icons/exercise/icons8-ski-simulator-50.svg',
    'assets/icons/exercise/icons8-skipping-rope-50.svg',
    'assets/icons/exercise/icons8-stretching-hamstring-50.svg',
    'assets/icons/exercise/icons8-stretching-skin-type-1-50.svg',
    'assets/icons/exercise/icons8-surfing-50.svg',
    'assets/icons/exercise/icons8-treadmill-50.svg',
    'assets/icons/exercise/icons8-trekking-50.svg',
    'assets/icons/exercise/icons8-triceps-50.svg',
    'assets/icons/exercise/icons8-walking-50.svg',
    'assets/icons/exercise/icons8-weightlifting-50.svg',
    'assets/icons/exercise/icons8-yoga-mat-50.svg',
    'assets/icons/exercise/icons8-yoga-skin-type-2-50.svg',
  ],
  'entertainment': [
    'assets/icons/entertainment/icons8-3d-glasses-50.svg',
    'assets/icons/entertainment/icons8-ark-survival-evolved-50.svg',
    'assets/icons/entertainment/icons8-baseball-player-skin-type-1-50.svg',
    'assets/icons/entertainment/icons8-big-drop-50.svg',
    'assets/icons/entertainment/icons8-board-game-50.svg',
    'assets/icons/entertainment/icons8-book-adaptation-50.svg',
    'assets/icons/entertainment/icons8-bowling-50.svg',
    'assets/icons/entertainment/icons8-breen-warship-50.svg',
    'assets/icons/entertainment/icons8-carousel-50.svg',
    'assets/icons/entertainment/icons8-cbs-50.svg',
    'assets/icons/entertainment/icons8-circus-cannon-50.svg',
    'assets/icons/entertainment/icons8-comics-magazine-50.svg',
    'assets/icons/entertainment/icons8-dancing-50.svg',
    'assets/icons/entertainment/icons8-dolby-digital-50.svg',
    'assets/icons/entertainment/icons8-drum-set-50.svg',
    'assets/icons/entertainment/icons8-ds3-tool-50.svg',
    'assets/icons/entertainment/icons8-elephant-circus-50.svg',
    'assets/icons/entertainment/icons8-entertainment-50-2.svg',
    'assets/icons/entertainment/icons8-entertainment-50-3.svg',
    'assets/icons/entertainment/icons8-entertainment-50-4.svg',
    'assets/icons/entertainment/icons8-entertainment-50-5.svg',
    'assets/icons/entertainment/icons8-entertainment-50-6.svg',
    'assets/icons/entertainment/icons8-entertainment-50-7.svg',
    'assets/icons/entertainment/icons8-entertainment-50.svg',
    'assets/icons/entertainment/icons8-fidget-spinner-50.svg',
    'assets/icons/entertainment/icons8-fortnite-llama-50.svg',
    'assets/icons/entertainment/icons8-game-controller-50.svg',
    'assets/icons/entertainment/icons8-gameboy-50.svg',
    'assets/icons/entertainment/icons8-iqiyi-50.svg',
    'assets/icons/entertainment/icons8-jet-ski-skin-type-4-50.svg',
    'assets/icons/entertainment/icons8-joy-con-50.svg',
    'assets/icons/entertainment/icons8-kite-50.svg',
    'assets/icons/entertainment/icons8-maracas-50.svg',
    'assets/icons/entertainment/icons8-marvel-50.svg',
    'assets/icons/entertainment/icons8-merry-go-round-50.svg',
    'assets/icons/entertainment/icons8-microsoft-mixer-50.svg',
    'assets/icons/entertainment/icons8-movie-projector-50.svg',
    'assets/icons/entertainment/icons8-music-festival-50.svg',
    'assets/icons/entertainment/icons8-nerf-gun-50.svg',
    'assets/icons/entertainment/icons8-netflix-desktop-app-50.svg',
    'assets/icons/entertainment/icons8-network-controller-50.svg',
    'assets/icons/entertainment/icons8-nintendo-64-50.svg',
    'assets/icons/entertainment/icons8-nintendo-entertainment-system-50.svg',
    'assets/icons/entertainment/icons8-nintendo-switch-50.svg',
    'assets/icons/entertainment/icons8-nintendo-switch-handheld-50.svg',
    'assets/icons/entertainment/icons8-nintendo-switch-logo-50.svg',
    'assets/icons/entertainment/icons8-playground-50.svg',
    'assets/icons/entertainment/icons8-playstation-buttons-50.svg',
    'assets/icons/entertainment/icons8-playstation-portable-50.svg',
    'assets/icons/entertainment/icons8-pool-table-50.svg',
    'assets/icons/entertainment/icons8-prodigy-50.svg',
    'assets/icons/entertainment/icons8-ps-5-50.svg',
    'assets/icons/entertainment/icons8-puzzle-50.svg',
    'assets/icons/entertainment/icons8-racquetball-50.svg',
    'assets/icons/entertainment/icons8-radio-studio-50.svg',
    'assets/icons/entertainment/icons8-reel-to-reel-50.svg',
    'assets/icons/entertainment/icons8-rockstar-games-50.svg',
    'assets/icons/entertainment/icons8-rockstar-social-club-50.svg',
    'assets/icons/entertainment/icons8-roller-coaster-50.svg',
    'assets/icons/entertainment/icons8-romantic-movies-50.svg',
    'assets/icons/entertainment/icons8-roulette-50.svg',
    'assets/icons/entertainment/icons8-seal-circus-50.svg',
    'assets/icons/entertainment/icons8-sock-puppet-50.svg',
    'assets/icons/entertainment/icons8-spaceship-earth-epcot-50.svg',
    'assets/icons/entertainment/icons8-sparkler-50.svg',
    'assets/icons/entertainment/icons8-super-nintendo-entertainment-system-50-2.svg',
    'assets/icons/entertainment/icons8-super-nintendo-entertainment-system-50.svg',
    'assets/icons/entertainment/icons8-theme-park-50.svg',
    'assets/icons/entertainment/icons8-ticket-50.svg',
    'assets/icons/entertainment/icons8-tire-swing-50.svg',
    'assets/icons/entertainment/icons8-video-editing-50.svg',
    'assets/icons/entertainment/icons8-viper-mark-2-50.svg',
    'assets/icons/entertainment/icons8-visual-game-boy-50.svg',
    'assets/icons/entertainment/icons8-watch-tv-50.svg',
    'assets/icons/entertainment/icons8-weverse-50.svg',
    'assets/icons/entertainment/icons8-zoo-50.svg',
    'assets/icons/entertainment/bilibili.svg',
    'assets/icons/entertainment/ChatGPT.svg',
    'assets/icons/entertainment/Claude.svg',
    'assets/icons/entertainment/gemini-ai.svg',
    'assets/icons/entertainment/telegram.svg',
    'assets/icons/entertainment/tiktok.svg',
    'assets/icons/entertainment/x.svg',
    'assets/icons/entertainment/youtube.svg',
    'assets/icons/entertainment/冒险 海贼 骷髅 海盗.svg',
    'assets/icons/entertainment/火影忍者.svg',
  ],
  'transportation': [
    'assets/icons/transportation/icons8-airplane-passenger-50.svg',
    'assets/icons/transportation/icons8-airport-50.svg',
    'assets/icons/transportation/icons8-auto-rickshaw-50.svg',
    'assets/icons/transportation/icons8-bus-depot-50.svg',
    'assets/icons/transportation/icons8-cable-car-50.svg',
    'assets/icons/transportation/icons8-city-railway-station-50.svg',
    'assets/icons/transportation/icons8-container-truck-50.svg',
    'assets/icons/transportation/icons8-convertible-50.svg',
    'assets/icons/transportation/icons8-defective-product-50.svg',
    'assets/icons/transportation/icons8-delivery-robot-50.svg',
    'assets/icons/transportation/icons8-ferry-50.svg',
    'assets/icons/transportation/icons8-fighter-jet-50.svg',
    'assets/icons/transportation/icons8-historic-ship-50.svg',
    'assets/icons/transportation/icons8-hospital-wheel-bed-50.svg',
    'assets/icons/transportation/icons8-ifv-50.svg',
    'assets/icons/transportation/icons8-imperial-star-destroyer-50.svg',
    'assets/icons/transportation/icons8-kick-scooter-50.svg',
    'assets/icons/transportation/icons8-klm-airlines-50.svg',
    'assets/icons/transportation/icons8-limousine-50.svg',
    'assets/icons/transportation/icons8-mercedes-benz-50.svg',
    'assets/icons/transportation/icons8-mine-trolley-50.svg',
    'assets/icons/transportation/icons8-motorcycle-50.svg',
    'assets/icons/transportation/icons8-oil-tanker-50.svg',
    'assets/icons/transportation/icons8-omega-class-destroyer-50.svg',
    'assets/icons/transportation/icons8-paid-parking-50.svg',
    'assets/icons/transportation/icons8-pickup-50.svg',
    'assets/icons/transportation/icons8-pickup-with-junk-50.svg',
    'assets/icons/transportation/icons8-police-car-50.svg',
    'assets/icons/transportation/icons8-port-50.svg',
    'assets/icons/transportation/icons8-railcar-50.svg',
    'assets/icons/transportation/icons8-semi-truck-side-view-50.svg',
    'assets/icons/transportation/icons8-shuttle-bus-50.svg',
    'assets/icons/transportation/icons8-sports-car-50.svg',
    'assets/icons/transportation/icons8-stop-sign-50.svg',
    'assets/icons/transportation/icons8-suv-50.svg',
    'assets/icons/transportation/icons8-taxi-50.svg',
    'assets/icons/transportation/icons8-tow-truck-50.svg',
    'assets/icons/transportation/icons8-trailer-unloading-50.svg',
    'assets/icons/transportation/icons8-train-50.svg',
    'assets/icons/transportation/icons8-train-ticket-50.svg',
    'assets/icons/transportation/icons8-tram-50.svg',
    'assets/icons/transportation/icons8-tram-side-view-50.svg',
    'assets/icons/transportation/icons8-transportation-50-2.svg',
    'assets/icons/transportation/icons8-transportation-50-3.svg',
    'assets/icons/transportation/icons8-transportation-50-4.svg',
    'assets/icons/transportation/icons8-transportation-50.svg',
    'assets/icons/transportation/icons8-travelator-50.svg',
    'assets/icons/transportation/icons8-tricycle-50.svg',
    'assets/icons/transportation/icons8-trolleybus-50.svg',
    'assets/icons/transportation/icons8-truck-ramp-50.svg',
    'assets/icons/transportation/icons8-underground-50.svg',
    'assets/icons/transportation/icons8-van-50.svg',
    'assets/icons/transportation/icons8-vaporetto-50.svg',
    'assets/icons/transportation/icons8-wagon-50.svg',
    'assets/icons/transportation/icons8-water-transportation-50.svg',
    'assets/icons/transportation/icons8-wheelbarrow-50.svg',
  ],
  'communication': [
    'assets/icons/communication/icons8-browse-page-50.svg',
    'assets/icons/communication/icons8-call-statistics-50.svg',
    'assets/icons/communication/icons8-comments-50.svg',
    'assets/icons/communication/icons8-communication-50-2.svg',
    'assets/icons/communication/icons8-communication-50.svg',
    'assets/icons/communication/icons8-facetime-50.svg',
    'assets/icons/communication/icons8-gmail-50.svg',
    'assets/icons/communication/icons8-gmail-logo-50.svg',
    'assets/icons/communication/icons8-google-meet-50-2.svg',
    'assets/icons/communication/icons8-google-meet-50-3.svg',
    'assets/icons/communication/icons8-google-meet-50.svg',
    'assets/icons/communication/icons8-incoming-call-50.svg',
    'assets/icons/communication/icons8-internal-call-50.svg',
    'assets/icons/communication/icons8-language-skill-50.svg',
    'assets/icons/communication/icons8-messages-50.svg',
    'assets/icons/communication/icons8-networking-manager-50.svg',
    'assets/icons/communication/icons8-online-50.svg',
    'assets/icons/communication/icons8-opposite-opinion-50.svg',
    'assets/icons/communication/icons8-phone-directory-50.svg',
    'assets/icons/communication/icons8-post-office-50.svg',
    'assets/icons/communication/icons8-qq-50.svg',
    'assets/icons/communication/icons8-radio-50.svg',
    'assets/icons/communication/icons8-rs-232-female-50.svg',
  ],
  'shopingIcon': [
    'assets/icons/shopingIcon/icons8-1-free-50.svg',
    'assets/icons/shopingIcon/icons8-add-shopping-cart-50.svg',
    'assets/icons/shopingIcon/icons8-add-tag-50.svg',
    'assets/icons/shopingIcon/icons8-banknotes-50.svg',
    'assets/icons/shopingIcon/icons8-black-friday-tag-50.svg',
    'assets/icons/shopingIcon/icons8-brand-new-50.svg',
    'assets/icons/shopingIcon/icons8-budget-50.svg',
    'assets/icons/shopingIcon/icons8-buy-50.svg',
    'assets/icons/shopingIcon/icons8-buying-50.svg',
    'assets/icons/shopingIcon/icons8-cash-50.svg',
    'assets/icons/shopingIcon/icons8-cash-register-50.svg',
    'assets/icons/shopingIcon/icons8-cheap-50.svg',
    'assets/icons/shopingIcon/icons8-cheque-50-2.svg',
    'assets/icons/shopingIcon/icons8-cheque-50.svg',
    'assets/icons/shopingIcon/icons8-cigarettes-pack-50.svg',
    'assets/icons/shopingIcon/icons8-coins-50.svg',
    'assets/icons/shopingIcon/icons8-confectionery-50.svg',
    'assets/icons/shopingIcon/icons8-coupon-50.svg',
    'assets/icons/shopingIcon/icons8-delivery-time-50.svg',
    'assets/icons/shopingIcon/icons8-discount-50.svg',
    'assets/icons/shopingIcon/icons8-dollar-bag-50.svg',
    'assets/icons/shopingIcon/icons8-dollar-coin-50.svg',
    'assets/icons/shopingIcon/icons8-gift-50-2.svg',
    'assets/icons/shopingIcon/icons8-gift-50.svg',
    'assets/icons/shopingIcon/icons8-google-shopping-50.svg',
    'assets/icons/shopingIcon/icons8-gratis-50.svg',
    'assets/icons/shopingIcon/icons8-home-decorations-50.svg',
    'assets/icons/shopingIcon/icons8-jewelry-50.svg',
    'assets/icons/shopingIcon/icons8-kitchenwares-50.svg',
    'assets/icons/shopingIcon/icons8-lighter-50.svg',
    'assets/icons/shopingIcon/icons8-low-price-50.svg',
    'assets/icons/shopingIcon/icons8-low-price-euro-50.svg',
    'assets/icons/shopingIcon/icons8-low-price-pound-50.svg',
    'assets/icons/shopingIcon/icons8-loyalty-card-50.svg',
    'assets/icons/shopingIcon/icons8-new-product-50.svg',
    'assets/icons/shopingIcon/icons8-paid-50.svg',
    'assets/icons/shopingIcon/icons8-plush-50.svg',
    'assets/icons/shopingIcon/icons8-price-comparison-50.svg',
    'assets/icons/shopingIcon/icons8-price-tag-50.svg',
    'assets/icons/shopingIcon/icons8-price-tag-usd-50.svg',
    'assets/icons/shopingIcon/icons8-product-50.svg',
    'assets/icons/shopingIcon/icons8-purse-50.svg',
    'assets/icons/shopingIcon/icons8-quality-50.svg',
    'assets/icons/shopingIcon/icons8-return-purchase-50.svg',
    'assets/icons/shopingIcon/icons8-sale-50.svg',
    'assets/icons/shopingIcon/icons8-self-service-kiosk-50.svg',
    'assets/icons/shopingIcon/icons8-shop-50.svg',
    'assets/icons/shopingIcon/icons8-shop-local-50.svg',
    'assets/icons/shopingIcon/icons8-shopaholic-50.svg',
    'assets/icons/shopingIcon/icons8-shopping-bag-50.svg',
    'assets/icons/shopingIcon/icons8-shopping-basket-50.svg',
    'assets/icons/shopingIcon/icons8-shopping-cart-50.svg',
    'assets/icons/shopingIcon/icons8-smoking-pipe-50.svg',
    'assets/icons/shopingIcon/icons8-souvenirs-50.svg',
    'assets/icons/shopingIcon/icons8-stationery-50.svg',
    'assets/icons/shopingIcon/icons8-tag-50.svg',
    'assets/icons/shopingIcon/icons8-tags-50.svg',
    'assets/icons/shopingIcon/icons8-tobacco-pouch-50.svg',
    'assets/icons/shopingIcon/icons8-used-product-50.svg',
    'assets/icons/shopingIcon/icons8-vending-machine-50.svg',
    'assets/icons/shopingIcon/icons8-wallet-50.svg',
    'assets/icons/shopingIcon/icons8-zippo-lighter-50.svg',
  ],
};


/// 图标选择器 Sheet
class IconPickerSheet extends StatefulWidget {
  final String? selectedIcon;
  const IconPickerSheet({super.key, this.selectedIcon});
  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet> {
  late String? _tempSelected;
  String _selectedCategory = '工作';
  List<String> _customIcons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedIcon;
    _loadCustomIcons();
    _locateCategory();
  }

  Future<void> _loadCustomIcons() async {
    final icons = await getCustomIcons();
    setState(() {
      _customIcons = icons;
      _isLoading = false;
    });
  }

  void _locateCategory() {
    if (_tempSelected == null) return;
    if (isCustomIcon(_tempSelected)) {
      _selectedCategory = '自定义';
    } else if (isSvgIcon(_tempSelected)) {
      final path = getSvgIconPath(_tempSelected);
      if (path != null) {
        for (final entry in svgIconCategories.entries) {
          if (path.contains('/${entry.value}/')) {
            _selectedCategory = entry.key;
            break;
          }
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final iconPath = await saveCustomIcon(File(image.path));
      await _loadCustomIcons();
      setState(() => _tempSelected = iconPath);
    }
  }

  Future<void> _deleteIcon(String path) async {
    await deleteCustomIcon(path);
    await _loadCustomIcons();
    if (_tempSelected != null && getCustomIconPath(_tempSelected) == path) {
      setState(() => _tempSelected = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [...svgIconCategories.keys, '自定义'];
    final isCustomCategory = _selectedCategory == '自定义';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('选择图标', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null)),
                if (_tempSelected != null)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: IconDisplay(icon: _tempSelected, size: 28),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                return Pressable(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : isCustomCategory
                    ? _buildCustomIconsGrid(isDark)
                    : _buildSvgIconsGrid(isDark),
          ),
          _buildBottomButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildSvgIconsGrid(bool isDark) {
    final categoryKey = svgIconCategories[_selectedCategory] ?? 'work';
    final icons = _allSvgIcons[categoryKey] ?? [];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final iconPath = icons[index];
        final iconValue = 'svg:$iconPath';
        final isSelected = _tempSelected == iconValue;

        return Pressable(
          onTap: () => setState(() => _tempSelected = iconValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.15) : (isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5)),
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(iconPath, width: 32, height: 32),
          ),
        );
      },
    );
  }

  Widget _buildCustomIconsGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _customIcons.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Pressable(
            onTap: _pickImage,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.primary),
            ),
          );
        }

        final iconPath = _customIcons[index - 1];
        final iconValue = 'custom:$iconPath';
        final isSelected = _tempSelected == iconValue;

        return GestureDetector(
          onTap: () => setState(() => _tempSelected = iconValue),
          onLongPress: () => _showDeleteDialog(iconPath),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSelected ? 10 : 12),
              child: Image.file(File(iconPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey))),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除图标'),
        content: const Text('确定要删除这个自定义图标吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteIcon(path);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF374151) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text('取消', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Pressable(
              onTap: () => Navigator.pop(context, _tempSelected),
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text('确认', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 显示图标选择器
Future<String?> showIconPicker(BuildContext context, {String? selectedIcon}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => IconPickerSheet(selectedIcon: selectedIcon),
  );
}
