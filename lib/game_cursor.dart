import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:win32/win32.dart' as win32;

/// 自定义 MouseCursor。
///
/// 与 `flutter_custom_cursor` 的 `FlutterCustomMemoryImageCursor` 不同，
/// 本类的 `activate()` 直接调用 Win32 `SetCursor`，使用预先注册缓存的
/// HCURSOR，完全不经过 Flutter 引擎的平台通道，也不会创建新的 HCURSOR。
/// 这避免了 Windows 在按住鼠标按钮拖动（SetCapture 状态）时，
/// 因高频 CreateCursor/SetCursor 导致的消息循环卡死问题。
///
/// 使用前先通过 [registerCursor] 注册对应名称的光标。
class GameCursor extends MouseCursor {
  /// 已注册的 Windows 自定义光标句柄缓存。
  ///
  /// key 为光标名，value 为 HCURSOR 句柄。
  static final Map<String, win32.HCURSOR> cursorHandles = {};

  static Future<void> registerCursors(Map<String, String> data) async {
    for (final entry in data.entries) {
      await registerCursor(name: entry.key, assetPath: entry.value);
    }
  }

  /// 将一个 PNG 光标图片注册为 Windows 自定义光标（HCURSOR）并缓存。
  ///
  /// 之后可以通过 [GameCursor]（作为 Flutter 的 MouseCursor 使用）来切换光标，
  /// 每次切换只做一次轻量的 Win32 `SetCursor`，不经过 Flutter 引擎的
  /// `setCustomCursor` 平台通道（该通道在 Windows 上每次都会重新创建 HCURSOR，
  /// 按住鼠标按钮拖动时的高频 WM_SETCURSOR 会造成消息循环卡死）。
  ///
  /// - [name]：光标名，作为缓存的 key，重复注册同名光标会先销毁旧的。
  /// - [assetPath]：光标 PNG 图片的 asset 路径。
  /// - [hotspot]：光标热点（指针尖在图片中的像素坐标），默认为 (0, 0)。
  ///   该坐标相对于原始 PNG 图片，函数内部会根据系统 DPI 自动换算。
  static Future<void> registerCursor({
    required String name,
    required String assetPath,
    (int, int) hotspot = (0, 0),
  }) async {
    final byteData = await rootBundle.load(assetPath);
    final pngBytes = byteData.buffer.asUint8List();
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      debugPrint('无法解码光标图片: $assetPath');
      return;
    }

    // Windows 的 SetSystemCursor（以及 CreateIconIndirect 创建的游标）
    // 会被系统缩放到 "系统光标大小"（通常为 SM_CXCURSOR，默认 32px，
    // 且随显示 DPI 缩放）。如果直接把原始尺寸的位图交给 CreateIconIndirect，
    // 系统缩放时使用的插值方式会导致光标位置出现偏差（表现为上下颠倒或错位）。
    // 因此这里先把图片缩放到目标尺寸，再创建光标。
    final views = PlatformDispatcher.instance.views;
    final dpr = views.isEmpty ? 1.0 : views.first.devicePixelRatio;
    final targetWidth = (32 * dpr).round();
    final targetHeight = (32 * dpr).round();

    final scaled =
        (decoded.width == targetWidth && decoded.height == targetHeight)
            ? decoded
            : img.copyResize(
                decoded,
                width: targetWidth,
                height: targetHeight,
                interpolation: img.Interpolation.cubic,
              );

    final width = scaled.width;
    final height = scaled.height;
    // image 包按 BGRA 顺序输出字节，正好是 Windows 位图需要的格式
    final bgra = scaled.getBytes(order: img.ChannelOrder.bgra);

    // AND mask（1bpp 单色位图）：位为 1 表示该像素透明（显示屏幕内容），
    // 位为 0 表示该像素由 XOR mask 决定（显示光标颜色）。
    // 根据 PNG 的 alpha 通道生成：alpha < 128 视为透明。
    // 位图按从下往上的行顺序存储（Windows 默认），因此写入时垂直翻转。
    final maskStride = ((width + 31) ~/ 32) * 4; // 每行字节数，4 字节对齐
    final andBits = calloc<Uint8>(maskStride * height);
    for (int y = 0; y < height; y++) {
      final srcY = height - 1 - y; // 垂直翻转
      for (int x = 0; x < width; x++) {
        final a = bgra[(srcY * width + x) * 4 + 3];
        if (a < 128) {
          andBits[y * maskStride + (x >> 3)] |= (0x80 >> (x & 7));
        }
      }
    }

    // XOR 颜色位图（32bpp BGRA），同样从下往上存储。
    final xorBits = calloc<Uint8>(width * height * 4);
    for (int y = 0; y < height; y++) {
      final srcY = height - 1 - y; // 垂直翻转
      for (int x = 0; x < width; x++) {
        final src = (srcY * width + x) * 4;
        final dst = (y * width + x) * 4;
        final a = bgra[src + 3];
        if (a < 128) {
          // 透明像素：颜色写 0，配合 AND mask=1 使该点显示屏幕内容
          xorBits[dst] = 0;
          xorBits[dst + 1] = 0;
          xorBits[dst + 2] = 0;
          xorBits[dst + 3] = 0;
        } else {
          xorBits[dst] = bgra[src];
          xorBits[dst + 1] = bgra[src + 1];
          xorBits[dst + 2] = bgra[src + 2];
          xorBits[dst + 3] = bgra[src + 3];
        }
      }
    }

    final hbmMask = win32.CreateBitmap(width, height, 1, 1, andBits);
    final hbmColor = win32.CreateBitmap(width, height, 1, 32, xorBits);

    calloc.free(andBits);
    calloc.free(xorBits);

    // 热点坐标也需要按图片缩放比例换算
    final hotX = (hotspot.$1 * width / decoded.width).round();
    final hotY = (hotspot.$2 * height / decoded.height).round();

    final iconInfo = calloc<win32.ICONINFO>();
    iconInfo.ref.fIcon = false; // false 表示这是光标而非图标
    iconInfo.ref.xHotspot = hotX;
    iconInfo.ref.yHotspot = hotY;
    iconInfo.ref.hbmMask = hbmMask;
    iconInfo.ref.hbmColor = hbmColor;

    final result = win32.CreateIconIndirect(iconInfo);
    calloc.free(iconInfo);

    // ICONINFO 里的位图在 CreateIconIndirect 之后即可释放，
    // 系统已经拷贝了一份用于光标。
    hbmMask.close();
    hbmColor.close();

    if (result.value.address == 0) {
      debugPrint('创建光标失败: $name, error=${result.error}');
      return;
    }

    // 重复注册同名光标时先销毁旧句柄
    final old = cursorHandles[name];
    if (old != null && old.isValid) {
      win32.DestroyCursor(old);
    }

    // CreateIconIndirect 返回 HICON，但对于光标来说与 HCURSOR 是同一个东西。
    cursorHandles[name] = win32.HCURSOR(result.value);
    debugPrint('注册光标: $name (${width}x$height, hotspot: $hotX,$hotY)');
  }

  /// 释放所有已注册的光标句柄（应用退出时可调用，通常不调用也无妨，
  /// 进程结束时系统会自动回收）。
  static void disposeCursors() {
    for (final hCursor in cursorHandles.values) {
      if (hCursor.isValid) {
        win32.DestroyCursor(hCursor);
      }
    }
    cursorHandles.clear();
  }

  final String name;

  const GameCursor({required this.name});

  @override
  MouseCursorSession createSession(int device) =>
      _GameCursorSession(this, device);

  @override
  String get debugDescription => 'GameCursor($name)';
}

class _GameCursorSession extends MouseCursorSession {
  _GameCursorSession(super.cursor, super.device);

  @override
  GameCursor get cursor => super.cursor as GameCursor;

  @override
  Future<void> activate() async {
    final hCursor = GameCursor.cursorHandles[cursor.name];
    if (hCursor != null && hCursor.isValid) {
      // 只做 SetCursor：告诉 Windows "当前使用该句柄"，
      // 这是 Windows 上最轻量的光标操作，不可能造成卡顿。
      win32.SetCursor(hCursor);
    }
  }

  @override
  void dispose() {}
}
