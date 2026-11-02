import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../../core/constants/app_colors.dart';

/// Custom Markdown element builder that renders syntax-highlighted code blocks
/// with language labels, copy buttons, and modern Claude-like dark container aesthetics.
class CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;

  CodeBlockBuilder({required this.isDark});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // Check if this is a pre > code block
    if (element.tag == 'pre') {
      final codeElement = element.children?.isNotEmpty == true
          ? element.children!.first
          : null;

      String codeText = element.textContent;
      String language = 'plaintext';

      if (codeElement is md.Element && codeElement.attributes.containsKey('class')) {
        final className = codeElement.attributes['class'] ?? '';
        if (className.startsWith('language-')) {
          language = className.replaceFirst('language-', '').toLowerCase();
        }
      }

      // Clean trailing newline
      if (codeText.endsWith('\n')) {
        codeText = codeText.substring(0, codeText.length - 1);
      }

      return CodeSnippetCard(
        code: codeText,
        language: language,
        isDarkScaffold: isDark,
      );
    }

    return null;
  }
}

/// Standalone code card with header, language badge, copy action, and syntax highlighting.
class CodeSnippetCard extends StatefulWidget {
  final String code;
  final String language;
  final bool isDarkScaffold;

  const CodeSnippetCard({
    super.key,
    required this.code,
    required this.language,
    this.isDarkScaffold = true,
  });

  @override
  State<CodeSnippetCard> createState() => _CodeSnippetCardState();
}

class _CodeSnippetCardState extends State<CodeSnippetCard> {
  bool _copied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(widget.code).length + 1;
    final displayLanguage = widget.language.isEmpty || widget.language == 'plaintext'
        ? 'code'
        : widget.language;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.codeBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.codeBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.codeHeaderBg,
              border: Border(
                bottom: BorderSide(color: AppColors.codeBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Language & Line Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayLanguage,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD4D4D8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$lineCount ${lineCount == 1 ? "line" : "lines"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),

                // Copy Code Action
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          _copied ? Icons.check : Icons.copy_rounded,
                          size: 13,
                          color: _copied
                              ? AppColors.accentEmerald
                              : const Color(0xFFA1A1AA),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _copied ? 'Copied!' : 'Copy code',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _copied
                                ? AppColors.accentEmerald
                                : const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Syntax Highlighted Body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: HighlightView(
              widget.code,
              language: widget.language.isEmpty ? 'plaintext' : widget.language,
              theme: atomOneDarkTheme,
              textStyle: GoogleFonts.jetBrainsMono(
                fontSize: 13.0,
                height: 1.55,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
