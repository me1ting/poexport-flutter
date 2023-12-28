import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CardBuildingCode extends StatefulWidget {
  const CardBuildingCode({
    super.key,
    required this.code,
  });

  final String? code;

  @override
  State<CardBuildingCode> createState() => _CardBuildingCodeState();
}

class _CardBuildingCodeState extends State<CardBuildingCode> {
  bool isCopying = false;

  final GlobalKey expanderKey = GlobalKey<ExpanderState>(
    debugLabel: 'Card Expander Key',
  );

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      constraints: const BoxConstraints(
        minHeight: 42.0,
      ),
      decoration: ShapeDecoration(
        color: theme.resources.cardBackgroundFillColorDefault,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.resources.cardStrokeColorDefault,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6.0),
            bottom: Radius.circular(6.0),
          ),
        ),
      ),
      padding: const EdgeInsetsDirectional.only(start: 16.0),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 10.0),
          ),
          Expanded(
              child: HorizontalScrollView(
            child: SelectableText(widget.code ?? ""),
          )),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 20.0, end: 10.0),
            child: Container(
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
                onPressed: widget.code == null || widget.code == ""
                    ? null
                    : () {
                        Clipboard.setData(
                            ClipboardData(text: widget.code ?? ""));
                        setState(() => isCopying = true);
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          isCopying = false;
                          if (mounted) setState(() {});
                        });
                      },
                child: isCopying
                    ? Icon(
                        FluentIcons.check_mark,
                        color: theme.resources.textOnAccentFillColorPrimary,
                        size: 18,
                      )
                    : Row(children: [
                        const Icon(FluentIcons.copy),
                        const SizedBox(width: 6.0),
                        Text(AppLocalizations.of(context)!.button_copy)
                      ]),
              ),
            ),
          )
        ],
      ),
    );

/*
    return Column(children: [
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
        trailing: Container(
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
              Clipboard.setData(ClipboardData(text: widget.code ?? ""));
              setState(() => isCopying = true);
              Future.delayed(const Duration(milliseconds: 1500), () {
                isCopying = false;
                if (mounted) setState(() {});
              });
            },
          ),
        ),
        header: HorizontalScrollView(
          child: SelectableText(widget.code ?? ""),
        ),
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
            code: widget.code ?? "",
            syntaxTheme: theme.brightness.isDark
                ? SyntaxTheme.vscodeDark()
                : SyntaxTheme.vscodeLight(),
          ),
        ),
      ),
    ]);
    */
  }
}
