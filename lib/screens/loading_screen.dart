/*---------------------------------------------------------------------------------------------
*  Copyright (c) nt4f04und. All rights reserved.
*  Licensed under the BSD-style license. See LICENSE in the project root for license information.
*--------------------------------------------------------------------------------------------*/

import 'package:flutter/material.dart';
import 'package:sweyer/constants.dart' as Constants;

/// TODO: probably add some fancy list loading animation here or when fetching songs instead of spinner
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Constants.AppTheme.main.auto(context),
      // backgroundColor: Constants.AppTheme.main.autoBr(Brightness.dark),
      // backgroundColor: Colors.red,
      // child: Center(
      //   child: CircularProgressIndicator(
      //     valueColor: const AlwaysStoppedAnimation(Colors.deepPurple),
      //   ),
      // ),
    );
  }
}
