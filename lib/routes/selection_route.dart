import 'package:flutter/material.dart';
import 'package:sweyer/sweyer.dart';

class SelectionRoute extends StatefulWidget {
  const SelectionRoute({
    Key? key,
    required this.selectionArguments,
  }) : super(key: key);

  final SelectionArguments selectionArguments;

  @override
  _SelectionRouteState createState() => _SelectionRouteState();
}

class _SelectionRouteState extends State<SelectionRoute> {
  late final HomeRouter nestedHomeRouter = HomeRouter.selection(widget.selectionArguments);
  late final ContentSelectionController controller;
  late ChildBackButtonDispatcher _backButtonDispatcher;
  bool settingsOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer back button dispatching to the child router
    _backButtonDispatcher = Router.of(context).backButtonDispatcher!.createChildBackButtonDispatcher();
  }

  @override
  void initState() {
    super.initState();
    controller = ContentSelectionController.createAlwaysInSelection(
      context: context,
      actionsBuilder: (context) {
        final l10n = getl10n(context);
        final settingsPageBuilder = widget.selectionArguments.settingsPageBuilder;
        return [
          if (settingsPageBuilder != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: settingsOpened
                  ? const SizedBox.shrink()
                  : NFIconButton(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () async {
                        if (!settingsOpened) {
                          setState(() {
                            settingsOpened = true;
                          });
                          await nestedHomeRouter.navigatorKey.currentState!.push(StackFadeRouteTransition(
                            child: Builder(builder: (context) => settingsPageBuilder(context)),
                            transitionSettings: AppRouter.instance.transitionSettings.greyDismissible,
                          ));
                          if (mounted) {
                            setState(() {
                              settingsOpened = false;
                            });
                          }
                        }
                      },
                    ),
            ),
          const SizedBox(width: 6.0),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) => AppButton(
              text: l10n.done,
              horizontalPadding: 20.0,
              onPressed: controller.data.isEmpty
                  ? null
                  : () {
                      widget.selectionArguments.onSubmit(controller.data);
                      Navigator.of(this.context).pop();
                    },
            ),
          ),
        ];
      },
    );
    widget.selectionArguments.selectionController = controller;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        controller.overlay = AppRouter.instance.navigatorKey.currentState!.overlay;
        controller.activate();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: kSongTileHeight(context)),
      child: Router<HomeRoutes>(
        routerDelegate: nestedHomeRouter,
        routeInformationParser: HomeRouteInformationParser(),
        routeInformationProvider: HomeRouteInformationProvider(),
        backButtonDispatcher: _backButtonDispatcher,
      ),
    );
  }
}
