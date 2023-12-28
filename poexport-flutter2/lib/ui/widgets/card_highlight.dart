import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';

class CardHighlight extends StatefulWidget {
  const CardHighlight({
    super.key,
    this.backgroundColor,
    this.header,
    required this.child,
    required this.codeSnippet,
  });

  final Widget? header;
  final Widget child;
  final String codeSnippet;

  final Color? backgroundColor;

  @override
  State<CardHighlight> createState() => _CardHighlightState();
}

class _CardHighlightState extends State<CardHighlight>
    with AutomaticKeepAliveClientMixin<CardHighlight> {
  bool isOpen = false;
  bool isCopying = false;

  final GlobalKey expanderKey = GlobalKey<ExpanderState>(
    debugLabel: 'Card Expander Key',
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = FluentTheme.of(context);

    return Column(children: [
      Mica(
        backgroundColor: widget.backgroundColor ??
            theme.resources.controlAltFillColorQuarternary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: double.infinity,
              child: widget.child,
            ),
          ),
        ),
      ),
      Expander(
        key: expanderKey,
        onStateChanged: (state) {
          // this is done because [onStateChanges] is called while the [Expander]
          // is updating. By using this, we schedule the rebuilt of this widget
          // to the next frame
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            if (mounted) setState(() => isOpen = state);
          });
        },
        trailing: isOpen
            ? Container(
                height: 31,
                constraints: const BoxConstraints(minWidth: 75),
                child: Button(
                  style: ButtonStyle(
                    backgroundColor: isCopying
                        ? ButtonState.all(
                            theme.accentColor.defaultBrushFor(theme.brightness),
                          )
                        : null,
                  ),
                  child: isCopying
                      ? Icon(
                          FluentIcons.check_mark,
                          color: theme.resources.textOnAccentFillColorPrimary,
                          size: 18,
                        )
                      : const Row(children: [
                          Icon(FluentIcons.copy),
                          SizedBox(width: 6.0),
                          Text('Copy')
                        ]),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.codeSnippet));
                    setState(() => isCopying = true);
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      isCopying = false;
                      if (mounted) setState(() {});
                    });
                  },
                ),
              )
            : null,
        header: widget.header ?? const Text('Source code'),
        headerShape: (open) {
          return const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.zero,
            ),
          );
        },
        content: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(6.0),
          ),
          child: SyntaxView(
            code: widget.codeSnippet.replaceAll('  ', '    '),
            syntaxTheme: theme.brightness.isDark
                ? SyntaxTheme.vscodeDark()
                : SyntaxTheme.vscodeLight(),
          ),
        ),
      ),
    ]);
  }

  @override
  bool get wantKeepAlive => true;
}
