import 'package:flutter/services.dart';
import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart' hide showBottomSheet, showGeneralDialog, showModalBottomSheet;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:collection/collection.dart';

/// Class that contains composed 'show' functions, like [showDialog] and others
class ShowFunctions extends NFShowFunctions {
  /// Empty constructor will allow inheritance.
  ShowFunctions();
  ShowFunctions._();
  static final instance = ShowFunctions._();

  /// Shows toast from `fluttertoast` plugin.
  Future<bool?> showToast({
    required String msg,
    Toast? toastLength,
    double fontSize = 15.0,
    ToastGravity? gravity,
    Color? textColor,
    Color? backgroundColor,
  }) async {
    backgroundColor ??= staticTheme.colorScheme.primary;

    return Fluttertoast.showToast(
      msg: msg,
      toastLength: toastLength,
      fontSize: fontSize,
      gravity: gravity,
      textColor: textColor,
      backgroundColor: backgroundColor,
      fontAsset: 'assets/fonts/Manrope/manrope-semibold.ttf',
      timeInSecForIosWeb: 20000,
    );
  }

  /// Opens songs search
  void showSongsSearch(
    BuildContext context, {
    String query = '',
    bool openKeyboard = true,
  }) {
    HomeRouter.of(context).goto(HomeRoutes.search.withArguments(SearchArguments(
      query: query,
      openKeyboard: openKeyboard,
    )));
  }

  /// Shows a dialog to create a playlist.
  Future<Playlist?> showCreatePlaylist(TickerProvider vsync, BuildContext context) async {
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    final enabled = ValueNotifier(false);
    controller.addListener(() {
      enabled.value = controller.text.trim().isNotEmpty;
    });
    bool submitted = false;
    String? name;
    Future<void> submit(BuildContext context) async {
      if (!submitted) {
        submitted = true;
        final navigator = Navigator.of(context);
        name = await ContentControl.instance.createPlaylist(controller.text);
        navigator.maybePop(name);
      }
    }

    await showDialog(
      context,
      ui: theme.systemUiThemeExtension.modalOverGrey,
      title: Text(l10n.newPlaylist),
      content: Builder(
        builder: (context) => AppTextField(
          autofocus: true,
          controller: controller,
          onSubmit: (value) {
            submit(context);
          },
          onDispose: () {
            controller.dispose();
          },
        ),
      ),
      buttonSplashColor: theme.appThemeExtension.glowSplashColor,
      acceptButton: ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (context, value, child) => AppButton.flat(
          text: l10n.create,
          splashColor: theme.appThemeExtension.glowSplashColor,
          onPressed: !value
              ? null
              : () async {
                  submit(context);
                },
        ),
      ),
    );
    return name == null ? null : ContentControl.instance.state.playlists.firstWhereOrNull((el) => el.name == name);
  }

  /// Will show up a snack bar notification that something's went wrong
  ///
  /// From that snack bar will be possible to proceed to special alert to see the error details with the ability to copy them.
  /// [errorDetails] string to show in the alert
  void showError({required String errorDetails}) {
    final context = AppRouter.instance.navigatorKey.currentContext!;
    final l10n = getl10n(context);
    final theme = Theme.of(context);
    final globalKey = GlobalKey<NFSnackbarEntryState>();
    NFSnackbarController.showSnackbar(
      NFSnackbarEntry(
        globalKey: globalKey,
        child: NFSnackbar(
          title: Text(
            l10n.oopsErrorOccurred,
            style: TextStyle(
              fontSize: 15.0,
              color: theme.colorScheme.onError,
            ),
          ),
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 4.0,
            bottom: 4.0,
          ),
          color: theme.colorScheme.error,
          trailing: AppButton(
            text: l10n.details,
            color: theme.colorScheme.onPrimary,
            textColor: Colors.black,
            onPressed: () {
              globalKey.currentState!.close();
              showAlert(
                context,
                title: Text(
                  l10n.errorDetails,
                  textAlign: TextAlign.center,
                ),
                titlePadding: defaultAlertTitlePadding.copyWith(
                  left: 12.0,
                  right: 12.0,
                ),
                contentPadding: const EdgeInsets.only(
                  top: 16.0,
                  left: 2.0,
                  right: 2.0,
                  bottom: 10.0,
                ),
                content: PrimaryScrollController(
                  controller: ScrollController(),
                  child: Builder(
                    builder: (context) {
                      return AppScrollbar(
                        child: SingleChildScrollView(
                          child: SelectableText(
                            errorDetails,
                            // TODO: temporarily do not apply AlwaysScrollableScrollPhysics, because of this issue https://github.com/flutter/flutter/issues/71342
                            // scrollPhysics: AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                            style: const TextStyle(fontSize: 11.0),
                            selectionControls: NFTextSelectionControls(
                              backgroundColor: theme.colorScheme.background,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                additionalActions: [
                  CopyButton(text: errorDetails),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<T?> showAlert<T extends Object?>(
    BuildContext context, {
    Widget? title,
    Widget? content,
    EdgeInsets titlePadding = defaultAlertTitlePadding,
    EdgeInsets contentPadding = defaultAlertContentPadding,
    Widget? closeButton,
    Color? buttonSplashColor,
    List<Widget>? additionalActions,
    SystemUiOverlayStyle? ui,
  }) async {
    final l10n = getl10n(context);
    title ??= Text(l10n.warning);
    closeButton ??= AppButton.pop(
      text: l10n.close,
      popResult: false,
      splashColor: buttonSplashColor,
    );
    return showDialog<T>(
      context,
      title: title,
      content: content,
      titlePadding: titlePadding,
      contentPadding: contentPadding,
      acceptButton: closeButton,
      cancelButton: const SizedBox.shrink(),
      buttonSplashColor: buttonSplashColor,
      additionalActions: additionalActions,
      ui: ui,
    );
  }

  @override
  Future<T?> showDialog<T extends Object?>(
    BuildContext context, {
    required Widget title,
    Widget? content,
    EdgeInsets titlePadding = defaultAlertTitlePadding,
    EdgeInsets contentPadding = defaultAlertContentPadding,
    Widget? acceptButton,
    Widget? cancelButton,
    Color? buttonSplashColor,
    List<Widget>? additionalActions,
    double borderRadius = 8.0,
    SystemUiOverlayStyle? ui,
  }) async {
    final l10n = getl10n(context);
    cancelButton ??= AppButton.pop(
      text: l10n.cancel,
      popResult: false,
      splashColor: buttonSplashColor,
    );
    return super.showDialog<T>(
      context,
      title: title,
      content: content,
      titlePadding: titlePadding,
      contentPadding: contentPadding,
      acceptButton: acceptButton,
      cancelButton: cancelButton,
      buttonSplashColor: buttonSplashColor,
      additionalActions: additionalActions,
      borderRadius: borderRadius,
      ui: ui,
    );
  }

  Future<void> showRadio<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemTitleBuilder,
    required ValueSetter<T> onItemSelected,
    required ValueGetter<T> groupValueGetter,
  }) {
    final theme = Theme.of(context);

    Widget buildItem(T item) {
      return Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NFListTileInkRipple.splashFactory,
        ),
        child: Builder(
          // i need the proper context to pop the dialog
          builder: (context) => AppRadioListTile<T>(
            title: Text(
              itemTitleBuilder(item),
              style: theme.textTheme.subtitle1,
            ),
            value: item,
            groupValue: groupValueGetter(),
            onChanged: (value) {
              onItemSelected(value);
              Navigator.pop(context);
            },
          ),
        ),
      );
    }

    return ShowFunctions.instance.showAlert(
      context,
      ui: theme.systemUiThemeExtension.modalOverGrey,
      title: Text(title),
      titlePadding: defaultAlertTitlePadding.copyWith(top: 20.0),
      contentPadding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      closeButton: const SizedBox.shrink(),
      content: AppScrollbar(
        isAlwaysShown: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: items.map((el) => buildItem(el)).toList(),
          ),
        ),
      ),
    );
  }
}
