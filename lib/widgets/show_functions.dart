import 'package:sweyer/sweyer.dart';
import 'package:flutter/material.dart'
    hide showBottomSheet, showGeneralDialog, showModalBottomSheet;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:collection/collection.dart';
import 'package:sweyer/constants.dart' as Constants;

/// Class that contains composed 'show' functions, like [showDialog] and others
class ShowFunctions extends NFShowFunctions {
  /// Empty constructor will allow enheritance.
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
    backgroundColor ??= ThemeControl.instance.theme.colorScheme.primary;

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
    final theme = ThemeControl.instance.theme;
    final TextEditingController controller = TextEditingController();
    final AnimationController animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    controller.addListener(() {
      if (controller.text.trim().isNotEmpty)
        animationController.forward();
      else
        animationController.reverse();
    });
    final animation = ColorTween(
      begin: theme.disabledColor,
      end: theme.colorScheme.onSecondary,
    ).animate(CurvedAnimation(
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
      parent: animationController,
    ));
    bool submitted = false;
    String? name;
    Future<void> submit(BuildContext context) async {
      if (!submitted) {
        submitted = true;
        name = await ContentControl.instance.createPlaylist(controller.text);
        Navigator.of(context).maybePop(name);
      }
    }
    await ShowFunctions.instance.showDialog(
      context,
      ui: Constants.UiTheme.modalOverGrey.auto,
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
            animationController.dispose();
          },
        ),
      ),
      buttonSplashColor: Constants.Theme.glowSplashColor.auto,
      acceptButton: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => IgnorePointer(
          ignoring: const IgnoringStrategy(
            dismissed: true,
            reverse: true,
          ).ask(animation),
          child: NFButton(
            text: l10n.create,
            textStyle: TextStyle(color: animation.value),
            splashColor: Constants.Theme.glowSplashColor.auto,
            onPressed: () async {
              submit(context);
            },
          ),
        ),
      ),
    );
    return name == null ? null : ContentControl.instance.state.playlists.firstWhereOrNull((el) => el.name == name); 
  }

  /// Will show up a snack bar notification that something's went wrong
  ///
  /// From that snack bar will be possible to proceed to special alert to see the error details with the ability to copy them.
  /// [errorDetails] string to show in the alert
  void showError({ required String errorDetails }) {
    final context = AppRouter.instance.navigatorKey.currentContext!;
    final l10n = getl10n(context);
    final theme = ThemeControl.instance.theme;
    final globalKey = GlobalKey<NFSnackbarEntryState>();
    NFSnackbarController.showSnackbar(
      NFSnackbarEntry(
        globalKey: globalKey,
        child: NFSnackbar(
          title: Text(
            '😮 ' + l10n.oopsErrorOccurred,
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
          trailing: NFButton(
            variant: NFButtonVariant.raised,
            text: l10n.details,
            color: theme.colorScheme.onPrimary,
            textStyle: const TextStyle(color: Colors.black),
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
                              backgroundColor: ThemeControl.instance.theme.colorScheme.background,
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),
                additionalActions: [
                  NFCopyButton(text: errorDetails),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
