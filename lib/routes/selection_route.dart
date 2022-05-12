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

  @override
  void initState() { 
    super.initState();
    var settingsOpened = false;
    controller = ContentSelectionController.createAlwaysInSelection(
      context: context,
      actionsBuilder: (context) {
        final l10n = getl10n(context);
        final settingsPageBuilder = widget.selectionArguments.settingsPageBuilder;
        return [
          if (settingsPageBuilder != null)
            NFIconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () async {
                if (!settingsOpened) {
                  settingsOpened = true;
                  await nestedHomeRouter.navigatorKey.currentState!.push(StackFadeRouteTransition(
                    child: Builder(builder: (context) => settingsPageBuilder(context)),
                    transitionSettings: AppRouter.instance.transitionSettings.greyDismissible,
                  ));
                  settingsOpened = false;
                }
              },
            ),
          const SizedBox(width: 6.0),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) => AppButton(
              text: l10n.done,
              horizontalPadding: 20.0,
              onPressed: controller.data.isEmpty ? null : () {
                widget.selectionArguments.onSubmit(controller.data);
                Navigator.of(this.context).pop();
              },
            ),
          ),
        ];
      },
    );
    widget.selectionArguments.selectionController = controller;
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (mounted) {
        controller.overlay = nestedHomeRouter.navigatorKey.currentState!.overlay;
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
     return Router<HomeRoutes>(
      routerDelegate: nestedHomeRouter,
      routeInformationParser: HomeRouteInformationParser(),
      routeInformationProvider: HomeRouteInformationProvider(),
      backButtonDispatcher: ChildBackButtonDispatcher(
        Router.of(context).backButtonDispatcher!,
      ),
    );
  }
}
