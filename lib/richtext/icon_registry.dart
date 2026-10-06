import 'package:flame/flame.dart';

/// 富文本内嵌图标的注册表。
///
/// 在游戏载入时通过 [register] / [registerAll] 注册图标 id 与资源路径的
/// 对应关系，然后调用 [preload] 将图片批量载入 Flame 的图片缓存。
///
/// 富文本标签 `<icon=xxx></>` 中的 `xxx` 即此处注册的 id。
abstract class RichTextIcons {
  RichTextIcons._();

  static final Map<String, String> _registry = {};

  /// [id] 为富文本标签中引用的图标 id，
  /// [path] 为相对于 `assets/images/` 的资源路径（含扩展名），
  /// 例如 `icon/sword.png`
  static void register(String id, String path) {
    _registry[id] = path;
  }

  static void registerAll(Map<String, String> icons) {
    _registry.addAll(icons);
  }

  static void unregister(String id) {
    _registry.remove(id);
  }

  static void clear() {
    _registry.clear();
  }

  static bool contains(String id) => _registry.containsKey(id);

  /// Flame 图片缓存的 key，即注册时的 [path] 本身
  static String? resolveFlameKey(String id) => _registry[id];

  /// Flutter 侧 [Image.asset] 需要的完整资源路径
  static String? resolveFlutterAsset(String id) {
    final path = _registry[id];
    return path != null ? 'assets/images/$path' : null;
  }

  /// 将所有已注册图标载入 Flame 图片缓存，供 Flame 侧渲染使用
  static Future<void> preload() {
    return Flame.images.loadAll(_registry.values.toList());
  }
}
