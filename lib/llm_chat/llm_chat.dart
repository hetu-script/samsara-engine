import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:samsara/engine.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/game_dialog/avatar.dart';

const String kDefaultSystemPrompt = "你是用户专属的个人助理。";

// --- 气泡组件 ---
class ChatBubble extends StatelessWidget {
  final String role;
  final String content;
  final bool isStreaming;
  final String? avatarImageId;
  final void Function(dynamic)? onPressed;
  final WidgetStateMouseCursor? cursor;
  final dynamic character;

  const ChatBubble({
    super.key,
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.avatarImageId,
    this.onPressed,
    this.cursor,
    this.character,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == "user";

    final contentWidget = isUser
        ? Text(
            content,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          )
        : GptMarkdown(
            content,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 非用户消息（助手）时，头像在左侧
          if (!isUser && avatarImageId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8.0),
              child: Avatar(
                imageId: avatarImageId,
                size: const Size(60, 60),
                cursor: cursor,
                onPressed: onPressed,
                data: character,
              ),
            ),
          // 气泡内容
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser ? Colors.lightBlue[100] : Colors.white,
                borderRadius: BorderRadius.all(const Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: contentWidget,
            ),
          ),
          // 用户消息时，头像在右侧
          if (isUser && avatarImageId != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Avatar(
                imageId: avatarImageId,
                size: const Size(60, 60),
                cursor: cursor,
                onPressed: onPressed,
                data: character,
              ),
            ),
        ],
      ),
    );
  }
}

// --- 主聊天视图 ---
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.engine,
    this.systemPrompt,
    this.npc,
    this.hero,
    this.backgroundColor,
    this.closeButton,
    this.label,
    this.labelStyle,
    this.onAvatarPressed,
    this.avatarCursor,
  });

  final SamsaraEngine engine;
  final String? systemPrompt;
  final dynamic npc;
  final dynamic hero;
  final Color? backgroundColor;
  final Widget? closeButton;
  final String? label;
  final TextStyle? labelStyle;
  final void Function(dynamic)? onAvatarPressed;
  final WidgetStateMouseCursor? avatarCursor;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ChatHistory chatHistory = ChatHistory();

  // 聊天状态
  final FocusNode _textFieldFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 流式输出相关
  bool _isGenerating = false;
  bool _isInitializing = true; // 标记是否正在初始化（预处理 system prompt）
  String _currentStreamBuffer = ""; // 暂存正在生成的文本
  StreamSubscription? _streamSubscription;
  StreamSubscription? _completionSubscription;

  LlamaParent get llamaParent => widget.engine.llamaParent;

  late String? charname;

  @override
  void initState() {
    super.initState();

    charname = widget.npc?['name'];

    _setupListeners();
    // 异步初始化，避免阻塞 UI
    // 初始化完成后会自动生成开场白，开场白完成后在 _finalizeMessage 中关闭 _isInitializing
    _initChat(systemPrompt: widget.systemPrompt ?? kDefaultSystemPrompt);
  }

  Future<void> _initChat({required String systemPrompt}) async {
    widget.engine.info("using prepared base state to initialize chat...");
    widget.engine.restoreBaseScope();

    // 追加角色特定信息
    final tempHistory = ChatHistory();
    tempHistory.addMessage(
      role: Role.system,
      content: '$systemPrompt\n\n结合以上信息，向用户给出一句话开场白。',
    );

    final characterPrompt = tempHistory.exportFormat(
      ChatFormat.gemma,
      leaveLastAssistantOpen: false,
    );

    // 发送角色信息（基于已加载的 base state）
    await llamaParent.sendPrompt(characterPrompt,
        scope: widget.engine.baseScope);

    widget.engine.info("llm chat initialized.");

    setState(() {
      _isGenerating = true;
      _currentStreamBuffer = "";
    });
  }

  void _setupListeners() {
    // 1. 监听 Token 流 (实现打字机效果的核心)
    _streamSubscription = llamaParent.stream.listen(
      (token) {
        setState(() {
          if (_currentStreamBuffer.isEmpty) {
            if (charname != null && charname!.contains(token)) return;
            if (token.trim().isEmpty) return;
            // 过滤掉多余的符号
            if (token == '</ul>') return;
            if (['·', '：'].contains(token)) return;
          }
          if (['“', '”', '"'].contains(token)) return;
          _currentStreamBuffer += token;
        });
      },
      onError: (e) {
        debugPrint("llama parent stream error: $e");
      },
    );

    // 2. 监听完成事件
    _completionSubscription = llamaParent.completions.listen((event) {
      if (event.success) {
        _finalizeMessage();
      }
    });
  }

  void _finalizeMessage() {
    if (_currentStreamBuffer.isNotEmpty) {
      setState(() {
        // 将完整的 buffer 存入历史记录，trim 去除首尾空白避免markdown渲染问题
        chatHistory.addMessage(
          role: Role.assistant,
          content: _currentStreamBuffer.trim(),
        );
        _currentStreamBuffer = "";
        _isInitializing = false;
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _textController.clear();
    FocusScope.of(context).unfocus(); // 收起键盘

    chatHistory.addMessage(role: Role.user, content: text);

    // 利用 KV Cache: 只发送新增的用户消息
    // Scope 会维护之前的上下文，无需重复发送整个历史
    final tempHistory = ChatHistory();
    tempHistory.addMessage(role: Role.user, content: text);
    String prompt = tempHistory.exportFormat(
      ChatFormat.gemma,
      leaveLastAssistantOpen: true,
    );

    setState(() {
      _isGenerating = true;
      _currentStreamBuffer = ""; // 清空 buffer 准备接收新回复
      _scrollToBottom();
    });

    // debugPrint('Sending incremental prompt: $prompt');
    await llamaParent.sendPrompt(prompt, scope: widget.engine.baseScope);
  }

  void _scrollToBottom() {
    // 使用微小的延迟确保 UI 渲染完当前帧后再滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
      _textFieldFocusNode.requestFocus(); // 生成完成后重新聚焦输入框
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _completionSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    llamaParent.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int
        // item count = 历史消息 + (正在生成的那一条 ? 1 : 0)
        itemCount = chatHistory.messages.length + (_isGenerating ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.npc?['name'] ?? ''),
        actions: [widget.closeButton ?? CloseButton()],
      ),
      body: Column(
        children: [
          // 聊天列表区域
          Expanded(
            child: itemCount > 0
                ? ScrollConfiguration(
                    behavior: MaterialScrollBehavior(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        shrinkWrap: true,
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          // 如果索引超出历史记录长度，说明是正在生成的那个 Bubble
                          if (index == chatHistory.messages.length) {
                            return _currentStreamBuffer.isNotEmpty
                                ? ChatBubble(
                                    role: "assistant",
                                    content: "$_currentStreamBuffer|", // 加个光标效果
                                    isStreaming: true,
                                    avatarImageId: widget.npc?['icon'],
                                    onPressed: widget.onAvatarPressed,
                                    cursor: widget.avatarCursor,
                                    character: widget.npc,
                                  )
                                : const SizedBox.shrink();
                          } else {
                            final msg = chatHistory.messages[index];
                            final isUserMsg = msg.role == Role.user;
                            return ChatBubble(
                              role: msg.role.name,
                              content: msg.content,
                              avatarImageId: isUserMsg
                                  ? (widget.hero?['icon'])
                                  : (widget.npc?['icon']),
                              onPressed: widget.onAvatarPressed,
                              cursor: widget.avatarCursor,
                              character: isUserMsg ? widget.hero : widget.npc,
                            );
                          }
                        },
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 底部输入区域
          if (_isGenerating || _isInitializing)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _isInitializing ? '正在初始化...' : '正在思考...',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const LinearProgressIndicator(),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: fluent.InfoLabel(
              label: widget.label ?? 'Press Enter to submit.',
              labelStyle: widget.labelStyle,
              child: fluent.TextBox(
                enabled: !_isGenerating &&
                    !_isInitializing &&
                    widget.engine.isLlamaReady,
                focusNode: _textFieldFocusNode,
                controller: _textController,
                autofocus: true,
                onSubmitted: (_) => _sendMessage(),
                suffix: fluent.IconButton(
                  icon: _isInitializing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isGenerating
                          ? const Icon(
                              Icons.stop_circle_outlined,
                              color: Colors.blueAccent,
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.greenAccent,
                            ),
                  onPressed: !widget.engine.isLlamaReady || _isInitializing
                      ? null
                      : _isGenerating
                          ? () async {
                              await llamaParent.stop();
                              setState(() {
                                _isGenerating = false;
                              });
                            }
                          : _sendMessage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
