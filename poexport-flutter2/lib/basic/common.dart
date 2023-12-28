import 'package:fluent_ui/fluent_ui.dart';

const appName = "CN POE Export";

void showError(BuildContext context, String title, String? message) {
  displayInfoBar(context, builder: (context, close) {
    return InfoBar(
      title: Text(title),
      content: message != null ? Text(message) : null,
      action: IconButton(
        icon: const Icon(FluentIcons.clear),
        onPressed: close,
      ),
      severity: InfoBarSeverity.error,
    );
  });
}

void showSuccess(BuildContext context, String title, String? message) {
  displayInfoBar(context, builder: (context, close) {
    return InfoBar(
      title: Text(title),
      content: message != null ? Text(message) : null,
      action: IconButton(
        icon: const Icon(FluentIcons.clear),
        onPressed: close,
      ),
      severity: InfoBarSeverity.success,
    );
  });
}
