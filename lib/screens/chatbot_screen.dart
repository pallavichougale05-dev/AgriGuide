import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';


class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({
    super.key,
  });

  @override
  State<ChatbotScreen> createState() =>
      _ChatbotScreenState();
}

// CHAT MESSAGE MODEL

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({
    required this.text,
    required this.isUser,
  });
}

// CHAT SCREEN STATE

class _ChatbotScreenState extends State<ChatbotScreen> {
  // CONTROLLERS

  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  // CHAT STATE

  final List<ChatMessage> messages = [];
  bool welcomeMessageAdded = false;
  String? lastLanguageCode;
  bool isTyping = false;

  // DISPOSE

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  // LANGUAGE CHANGE HANDLING

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final String currentLanguage =
        Localizations.localeOf(context).languageCode;

    if (!welcomeMessageAdded) {
      addWelcomeMessage();
      return;
    }

    // Only change the welcome message when there is no
    // real conversation yet.
    if (lastLanguageCode != currentLanguage &&
        messages.length == 1 &&
        !isTyping) {
      setState(() {
        messages.clear();

        addLocalizedWelcomeMessage();

        lastLanguageCode = currentLanguage;
      });
    }
  }

  // ADD WELCOME MESSAGE
  void addWelcomeMessage() {
    final String currentLanguage =
        Localizations.localeOf(context).languageCode;

    if (welcomeMessageAdded) {
      return;
    }

    setState(() {
      addLocalizedWelcomeMessage();

      welcomeMessageAdded = true;

      lastLanguageCode = currentLanguage;
    });
  }

  // LOCALIZED WELCOME MESSAGE

  void addLocalizedWelcomeMessage() {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    messages.add(
      ChatMessage(
        text: l10n.assistantGreeting,
        isUser: false,
      ),
    );
  }


  // CHECK CURRENT LANGUAGE

  bool isMarathi() {
    return Localizations.localeOf(context)
            .languageCode ==
        'mr';
  }

  // SEND MESSAGE

  Future<void> sendMessage() async {
    final String userText =
        messageController.text.trim();

    if (userText.isEmpty || isTyping) {
      return;
    }
    // ADD FARMER MESSAGE

    setState(() {
      messages.add(
        ChatMessage(
          text: userText,
          isUser: true,
        ),
      );

      messageController.clear();

      isTyping = true;
    });

    scrollToBottom();

    try {
      // CREATE BACKEND QUESTION

      String backendQuestion;

      if (isMarathi()) {
        backendQuestion = '''
Answer the following farmer's question in Marathi.

Use clear, simple Marathi that an Indian farmer can easily understand.

Give practical and useful agriculture advice.

Use simple formatting when useful:
- Use bold-style emphasis only when necessary.
- Use numbered steps for recommendations.
- Use bullet points for short lists.
- Keep paragraphs easy to read.
Farmer's question:

$userText
''';
      } else {
        backendQuestion = '''
Answer the following farmer's question in English.

Use clear and simple English that an Indian farmer can easily understand.

Give practical and useful agriculture advice.

Use simple formatting when useful:
- Use bold-style emphasis only when necessary.
- Use numbered steps for recommendations.
- Use bullet points for short lists.
- Keep paragraphs easy to read.

Do not leave incomplete formatting markers such as ** or __.

Farmer's question:

$userText
''';
      }
      // SEND TO FASTAPI

      final String response =
          await ApiService.sendChatMessage(
        backendQuestion,
      );

      if (!mounted) {
        return;
      }
      // ADD ASSISTANT RESPONSE

      setState(() {
        messages.add(
          ChatMessage(
            text: response,
            isUser: false,
          ),
        );

        isTyping = false;
      });

      scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final AppLocalizations l10n =
          AppLocalizations.of(context)!;

      setState(() {
        messages.add(
          ChatMessage(
            text: l10n.assistantError,
            isUser: false,
          ),
        );

        isTyping = false;
      });

      scrollToBottom();
    }
  }

  // SCROLL TO BOTTOM

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted ||
            !scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // GET SUGGESTIONS

  List<String> getSuggestions() {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    return [
      l10n.cropQuestions,
      l10n.irrigationQuestions,
      l10n.soilQuestions,
      l10n.pestQuestions,
    ];
  }

  // CLEAN ASSISTANT RESPONSE
 

  String cleanAssistantText(
    String text,
  ) {
    String result = text
        .replaceAll(
          '\r\n',
          '\n',
        )
        .replaceAll(
          '\r',
          '\n',
        )
        .replaceAll(
          '\u200B',
          '',
        )
        .trim();

    // Remove Markdown bold markers.
    // This safely handles both valid and incomplete markers.
    result = result.replaceAll(
      '**',
      '',
    );

    result = result.replaceAll(
      '__',
      '',
    );

    // Process every line separately.

    final List<String> lines =
        result.split('\n');

    final List<String> cleanedLines = [];

    for (String line in lines) {
      String cleanedLine =
          line.trimLeft();

      // ------------------------------------------------------
      // Remove Markdown heading markers.
      // ------------------------------------------------------

      if (cleanedLine.startsWith(
        '###### ',
      )) {
        cleanedLine =
            cleanedLine.substring(7);
      } else if (cleanedLine.startsWith(
        '##### ',
      )) {
        cleanedLine =
            cleanedLine.substring(6);
      } else if (cleanedLine.startsWith(
        '#### ',
      )) {
        cleanedLine =
            cleanedLine.substring(5);
      } else if (cleanedLine.startsWith(
        '### ',
      )) {
        cleanedLine =
            cleanedLine.substring(4);
      } else if (cleanedLine.startsWith(
        '## ',
      )) {
        cleanedLine =
            cleanedLine.substring(3);
      } else if (cleanedLine.startsWith(
        '# ',
      )) {
        cleanedLine =
            cleanedLine.substring(2);
      }

      // ------------------------------------------------------
      // Convert Markdown bullet markers into real bullets.
      // ------------------------------------------------------

      if (cleanedLine.startsWith('- ')) {
        cleanedLine =
            '• ${cleanedLine.substring(2)}';
      } else if (cleanedLine.startsWith('* ')) {
        cleanedLine =
            '• ${cleanedLine.substring(2)}';
      } else if (cleanedLine.startsWith('+ ')) {
        cleanedLine =
            '• ${cleanedLine.substring(2)}';
      }

      cleanedLines.add(
        cleanedLine,
      );
    }

    result = cleanedLines.join('\n');

    // --------------------------------------------------------
    // Remove excessive blank lines.
    // --------------------------------------------------------

    while (result.contains('\n\n\n')) {
      result = result.replaceAll(
        '\n\n\n',
        '\n\n',
      );
    }

    return result.trim();
  }


  // ==========================================================
  // ASSISTANT RESPONSE
  // ==========================================================

  Widget buildAssistantContent(
    String text,
  ) {
    final String cleaned =
        cleanAssistantText(text);

    return SelectableText(
      cleaned,
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.55,
        color: Color(0xFF405047),
      ),
    );
  }


  // ==========================================================
  // COPY ASSISTANT RESPONSE
  // ==========================================================

  Future<void> copyAssistantResponse(
    String text,
  ) async {
    final String cleaned =
        cleanAssistantText(text);

    await Clipboard.setData(
      ClipboardData(
        text: cleaned,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Response copied.',
        ),
        behavior:
            SnackBarBehavior.floating,
        duration:
            Duration(seconds: 2),
      ),
    );
  }


  // ==========================================================
  // SCREEN UI
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // final AppLocalizations l10n =
    //     AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F8F3),

      // APP BAR

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF168A52),

        foregroundColor:
            Colors.white,

        elevation: 0,

        scrolledUnderElevation: 0,

        toolbarHeight: 68,

        titleSpacing: 0,

        title: Row(
          children: [
            // ASSISTANT AVATAR

            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFF3B9868,
                ),
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      const Color(
                    0xFF67B587,
                  ),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),

            const SizedBox(
              width: 11,
            ),

            // TITLE + STATUS

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    isMarathi() ? 'शेती सहाय्यक' : 'Farming Assistant',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            const BoxDecoration(
                          color:
                              Color(
                            0xFFB8E7C4,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      const Text(
                        'Agriculture Assistant',
                        style:
                            TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              FontWeight.w500,
                          color:
                              Color(
                            0xFFDDF2E3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),


      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: Column(
          children: [
            // =================================================
            // CHAT LIST
            // =================================================

            Expanded(
              child:
                  messages.isEmpty
                      ? buildEmptyState()
                      : ListView.builder(
                          controller:
                              scrollController,

                          physics:
                              const BouncingScrollPhysics(),

                          padding:
                              const EdgeInsets.fromLTRB(
                            14,
                            16,
                            14,
                            14,
                          ),

                          itemCount:
                              messages.length +
                                  (isTyping
                                      ? 1
                                      : 0) +
                                  (messages.length ==
                                          1
                                      ? 1
                                      : 0),

                          itemBuilder:
                              (
                            BuildContext context,
                            int index,
                          ) {
                            // ------------------------------------
                            // SUGGESTIONS
                            // ------------------------------------

                            if (messages.length ==
                                    1 &&
                                index == 1) {
                              return buildSuggestions();
                            }


                            // ------------------------------------
                            // TYPING INDICATOR
                            // ------------------------------------

                            final int typingIndex =
                                messages.length +
                                    (messages.length ==
                                            1
                                        ? 1
                                        : 0);

                            if (isTyping &&
                                index ==
                                    typingIndex) {
                              return buildTypingIndicator();
                            }


                            // ------------------------------------
                            // MESSAGE INDEX
                            // ------------------------------------

                            int messageIndex =
                                index;

                            if (messages.length ==
                                    1 &&
                                index > 1) {
                              messageIndex--;
                            }


                            // ------------------------------------
                            // SAFETY CHECK
                            // ------------------------------------

                            if (messageIndex <
                                    0 ||
                                messageIndex >=
                                    messages.length) {
                              return const SizedBox.shrink();
                            }


                            return buildMessageBubble(
                              messages[
                                  messageIndex],
                            );
                          },
                        ),
            ),


            // =================================================
            // INPUT AREA
            // =================================================

            buildMessageInput(),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 76,
              height: 76,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFE5F2E6,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .agriculture_rounded,
                size: 34,
                color:
                    Color(
                  0xFF3F8D4A,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'How can I help with your farm?',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF29372D),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Ask about crops, soil, irrigation, '
              'pests, diseases, or farming practices.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.5,
                color:
                    Color(0xFF778078),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // MESSAGE BUBBLE
  // ==========================================================

  Widget buildMessageBubble(
    ChatMessage message,
  ) {
    final bool isUser =
        message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 340,
        ),

        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),

        child: Column(
          crossAxisAlignment:
              isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,

          children: [
            // MESSAGE LABEL
            if (!isUser)
              Padding(
                padding:
                    const EdgeInsets.only(
                  left: 8,
                  bottom: 5,
                ),

                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(
                          0xFFE3F0E4,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons
                            .smart_toy_rounded,
                        size: 13,
                        color:
                            Color(
                          0xFF4B8F52,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    const Text(
                      'AgriGuide',
                      style:
                        TextStyle(
                        fontSize: 9.5,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(
                          0xFF718078,
                        ),
                      ),
                    ),
                  ],
                ),
              ),


            // MESSAGE CARD

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),

              decoration:
                  BoxDecoration(
                color: isUser
                    ? const Color(
                        0xFF168A52,
                      )
                    : Colors.white,

                borderRadius:
                    BorderRadius.only(
                  topLeft:
                      const Radius.circular(
                    19,
                  ),
                  topRight:
                      const Radius.circular(
                    19,
                  ),
                  bottomLeft:
                      Radius.circular(
                    isUser ? 19 : 5,
                  ),
                  bottomRight:
                      Radius.circular(
                    isUser ? 5 : 19,
                  ),
                ),

                border: isUser
                    ? null
                    : Border.all(
                        color:
                            const Color(
                          0xFFE0E7DF,
                        ),
                      ),

                boxShadow:
                    isUser
                        ? const [
                            BoxShadow(
                              color:
                                  Color(
                                0x15168A52,
                              ),
                              blurRadius:
                                  9,
                              offset:
                                  Offset(
                                0,
                                4,
                              ),
                            ),
                          ]
                        : const [
                            BoxShadow(
                              color:
                                  Color(
                                0x081E3A24,
                              ),
                              blurRadius:
                                  12,
                              offset:
                                  Offset(
                                0,
                                4,
                              ),
                            ),
                          ],
              ),

              child: isUser
                  ? Text(
                      message.text,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color:
                            Colors.white,
                      ),
                    )
                  : buildAssistantContent(
                      message.text,
                    ),
            ),


            // ------------------------------------------------
            // COPY ACTION FOR ASSISTANT
            // ------------------------------------------------

            if (!isUser)
              Padding(
                padding:
                    const EdgeInsets.only(
                  left: 4,
                  top: 3,
                ),

                child:
                    GestureDetector(
                  onTap: () {
                    copyAssistantResponse(
                      message.text,
                    );
                  },

                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),

                    child: const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .content_copy_rounded,
                          size: 13,
                          color:
                              Color(
                            0xFF87918A,
                          ),
                        ),

                        SizedBox(
                          width: 4,
                        ),

                        Text(
                          'Copy',
                          style:
                              TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Color(
                              0xFF87918A,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // SUGGESTED QUESTIONS
  // ==========================================================

  Widget buildSuggestions() {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    final List<String> suggestions =
        getSuggestions();

    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        top: 2,
        bottom: 16,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF0F6ED),

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFDCE9D8,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFDCECD9),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .lightbulb_outline_rounded,
                  size: 15,
                  color:
                      Color(0xFF5B8E5B),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                l10n.tryAsking,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF4C6953),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Wrap(
            spacing: 7,
            runSpacing: 7,

            children:
                suggestions.map(
              (
                String suggestion,
              ) {
                return GestureDetector(
                  onTap: () {
                    messageController
                            .text =
                        suggestion;

                    sendMessage();
                  },

                  child:
                      Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 290,
                    ),

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,

                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),

                      border:
                          Border.all(
                        color:
                            const Color(
                          0xFFD7E4D3,
                        ),
                      ),
                    ),

                    child:
                        Text(
                      suggestion,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(
                          0xFF477154,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // TYPING INDICATOR
  // ==========================================================

  Widget buildTypingIndicator() {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    return Align(
      alignment:
          Alignment.centerLeft,

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
          left: 3,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            17,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFFE0E7DF,
            ),
          ),

          boxShadow:
              const [
            BoxShadow(
              color:
                  Color(0x081E3A24),
              blurRadius: 10,
              offset:
                  Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Container(
              width: 27,
              height: 27,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFE6F2E4),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Padding(
                padding:
                    EdgeInsets.all(
                  6,
                ),
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      Color(
                    0xFF4E8A55,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Text(
              l10n.assistantThinking,
              style:
                  const TextStyle(
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF778078),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // MESSAGE INPUT
  // ==========================================================

  Widget buildMessageInput() {
    final AppLocalizations l10n =
        AppLocalizations.of(context)!;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        9,
        12,
        10,
      ),

      decoration:
          const BoxDecoration(
        color: Colors.white,

        border: Border(
          top: BorderSide(
            color:
                Color(0xFFE1E7E0),
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Color(0x0A1E3A24),
            blurRadius: 10,
            offset:
                Offset(0, -3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,

        children: [
          // ==================================================
          // TEXT FIELD
          // ==================================================

          Expanded(
            child: Container(
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF3F6F1,
                ),

                borderRadius:
                    BorderRadius.circular(
                  21,
                ),

                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFE0E7DF,
                  ),
                ),
              ),

              child: TextField(
                controller:
                    messageController,

                minLines: 1,

                maxLines: 4,

                textInputAction:
                    TextInputAction.newline,

                decoration:
                    InputDecoration(
                  hintText:
                      l10n.askAboutFarming,

                  hintStyle:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(
                      0xFF9AA29C,
                    ),
                  ),

                  border:
                      InputBorder.none,

                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                ),

                onSubmitted: (_) {
                  sendMessage();
                },
              ),
            ),
          ),


          const SizedBox(
            width: 8,
          ),


          // ==================================================
          // SEND BUTTON
          // ==================================================

          Semantics(
            button: true,

            label: l10n.send,

            child:
                GestureDetector(
              onTap:
                  isTyping
                      ? null
                      : sendMessage,

              child:
                  AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 180,
                ),

                width: 47,
                height: 47,

                decoration:
                    BoxDecoration(
                  color: isTyping
                      ? const Color(
                          0xFF9EB7A5,
                        )
                      : const Color(
                          0xFF168A52,
                        ),

                  shape:
                      BoxShape.circle,

                  boxShadow:
                      isTyping
                          ? null
                          : const [
                              BoxShadow(
                                color:
                                    Color(
                                  0x24168A52,
                                ),
                                blurRadius:
                                    9,
                                offset:
                                    Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ],
                ),

                child: isTyping
                    ? const Padding(
                        padding:
                            EdgeInsets.all(
                          13,
                        ),
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .arrow_upward_rounded,
                        size: 21,
                        color:
                            Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}