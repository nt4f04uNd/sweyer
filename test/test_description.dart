import 'package:sweyer/sweyer.dart';

TestDescription getTestDescription({
  required bool lightTheme,
  required PlayerInterfaceColorStyle? playerInterfaceColorStyle,
}) {
  TestDescription description = const TestDescriptorBase();
  description = TestDescriptorWithPlayerInterfaceColorStyle(
    description,
    playerInterfaceColorStyle: playerInterfaceColorStyle,
  );
  description = TestDescriptorWithLightAndDarkTheme(
    description,
    lightTheme: lightTheme,
  );
  return description;
}

abstract class TestDescription {
  const TestDescription();

  String buildFileName(String name);
  String buildDescription(String description);
}

abstract class TestDescriptor extends TestDescription {
  const TestDescriptor(this.wrapped);

  final TestDescription? wrapped;
}

abstract class RequiredTestDescriptor extends TestDescription {
  const RequiredTestDescriptor(this.wrapped);

  final TestDescription wrapped;
}

class TestDescriptorBase extends TestDescriptor {
  const TestDescriptorBase() : super(null);

  @override
  String buildFileName(String name) => name;

  @override
  String buildDescription(String description) => description;
}

class TestDescriptorWithLightAndDarkTheme extends RequiredTestDescriptor {
  const TestDescriptorWithLightAndDarkTheme(
    super.wrapped, {
    required this.lightTheme,
  });

  final bool lightTheme;

  String _getMessage() => lightTheme ? 'light' : 'dark';

  @override
  String buildFileName(String name) {
    final original = wrapped.buildFileName(name);
    return '$original.${_getMessage()}';
  }

  @override
  String buildDescription(String description) {
    final original = wrapped.buildFileName(description);
    return '$original | theme ${_getMessage()}';
  }
}

class TestDescriptorWithPlayerInterfaceColorStyle extends RequiredTestDescriptor {
  const TestDescriptorWithPlayerInterfaceColorStyle(
    super.wrapped, {
    required this.playerInterfaceColorStyle,
  });

  final PlayerInterfaceColorStyle? playerInterfaceColorStyle;

  String _getMessage() => playerInterfaceColorStyle!.name;

  @override
  String buildFileName(String name) {
    final original = wrapped.buildFileName(name);
    if (playerInterfaceColorStyle == null) {
      return original;
    }
    return '$original.${_getMessage()}';
  }

  @override
  String buildDescription(String description) {
    final original = wrapped.buildFileName(description);
    if (playerInterfaceColorStyle == null) {
      return original;
    }
    return '$original | player interface color ${_getMessage()}';
  }
}
