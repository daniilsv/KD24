import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

typedef AppBar AppBarCallback(BuildContext context);
typedef void TextFieldSubmitCallback(String value);
typedef void TextFieldClearCallback();
typedef void SetStateCallback(void fn());

class SearchBar {
  /// Whether the search should take place "in the existing search bar", meaning whether it has the same background or a flipped one. Defaults to true.
  final bool inBar;

  /// Whether the back button should be colored, if this is false the back button will be Colors.grey.shade400
  final bool colorBackButton;

  /// Whether or not the search bar should close on submit. Defaults to true.
  final bool closeOnSubmit;

  /// Whether the text field should be cleared when it is submitted
  final bool clearOnSubmit;

  /// A callback which should return an AppBar that is displayed until search is started. One of the actions in this AppBar should be a search button which you obtain from SearchBar.getSearchAction(). This will be called every time search is ended, etc. (like a build method on a widget)
  final AppBarCallback buildDefaultAppBar;

  /// A void callback which takes a string as an argument, this is fired every time the search is submitted. Do what you want with the result.
  final TextFieldSubmitCallback onSubmitted;

  final TextFieldSubmitCallback onType;

  final TextFieldClearCallback onClear;

  /// Since this should be inside of a State class, just pass setState to this.
  final SetStateCallback setState;

  /// Whether or not the search bar should add a clear input button, defaults to true.
  final bool showClearButton;

  /// What the hintText on the search bar should be. Defaults to 'Search'.
  String hintText;

  /// The controller to be used in the textField.
  TextEditingController controller;

  /// Whether search is currently active.
  bool _isSearching = false;

  /// Whether the clear button should be active (fully colored) or inactive (greyed out)
  bool _clearActive = false;

  /// The last built default AppBar used for colors and such.
  AppBar _defaultAppBar;

  bool needBarCodeCamera = false;

  SearchBar({@required this.setState,
    @required this.buildDefaultAppBar,
    this.onSubmitted,
    this.onType,
    this.onClear,
    this.controller,
    this.hintText = 'Search',
    this.inBar = true,
    this.colorBackButton = true,
    this.needBarCodeCamera = false,
    this.closeOnSubmit = true,
    this.clearOnSubmit = true,
    this.showClearButton = true}) {
    if (this.controller == null) {
      this.controller = new TextEditingController();
    }

    // Don't waste resources on listeners for the text controller if the dev
    // doesn't want a clear button anyways in the search bar
    if (!this.showClearButton) {
      return;
    }

    this.controller.addListener(() {
      if (this.controller.text.isEmpty) {
        // If clear is already disabled, don't disable it
        if (_clearActive) {
          setState(() {
            _clearActive = false;
          });
        }
        onClear();
        return;
      }
      onType(this.controller.text);
      // If clear is already enabled, don't enable it
      if (!_clearActive) {
        setState(() {
          _clearActive = true;
        });
      }
    });
  }

  /// Whether search is currently active.
  bool get isSearching => _isSearching;

  /// Initializes the search bar.
  ///
  /// This adds a new route that listens for onRemove (and stops the search when that happens), and then calls [setState] to rebuild and start the search.
  void beginSearch(context) {
    ModalRoute.of(context).addLocalHistoryEntry(new LocalHistoryEntry(onRemove: () {
      setState(() {
        controller.text = "";
        onType("");
        _isSearching = false;
      });
    }));

    setState(() {
      _isSearching = true;
    });
  }

  /// Builds, saves and returns the default app bar.
  ///
  /// This calls the [buildDefaultAppBar] provided in the constructor, and saves it to [_defaultAppBar].
  AppBar buildAppBar(BuildContext context) {
    _defaultAppBar = buildDefaultAppBar(context);

    return _defaultAppBar;
  }

  /// Builds the search bar!
  ///
  /// The leading will always be a back button.
  /// backgroundColor is determined by the value of inBar
  /// title is always a [TextField] with the key 'SearchBarTextField', and various text stylings based on [inBar]. This is also where [onSubmitted] has its listener registered.
  ///
  AppBar buildSearchBar(BuildContext context) {
    ThemeData theme = Theme.of(context);

    Color barColor = inBar ? _defaultAppBar.backgroundColor : theme.canvasColor;

    // Don't provide a color (make it white) if it's in the bar, otherwise color it or set it to grey.
    Color buttonColor = inBar
        ? null
        : (colorBackButton
        ? _defaultAppBar.backgroundColor ?? theme.primaryColor ?? Colors.grey.shade400
        : Colors.grey.shade400);
    Color buttonDisabledColor = inBar ? new Color.fromRGBO(255, 255, 255, 0.25) : Colors.grey.shade300;

    Color textColor = inBar ? Colors.white70 : Colors.black54;

    return new AppBar(
      leading: new BackButton(color: buttonColor),
      backgroundColor: barColor,
      title: new Directionality(
        textDirection: Directionality.of(context),
        child: new TextFormField(
          style: new TextStyle(color: textColor, fontSize: 16.0),
          key: new Key('SearchBarTextField'),
          keyboardType: TextInputType.text,
          onSaved: (String val) async {
            if (closeOnSubmit) {
              await Navigator.maybePop(context);
            }

            if (clearOnSubmit) {
              controller.clear();
            }

            onSubmitted(val);
          },
          autofocus: true,
          controller: controller,
          decoration: new InputDecoration(
              hintText: hintText, hintStyle: new TextStyle(color: textColor, fontSize: 16.0), border: null),
        ),
      ),
      actions: <Widget>[
        _clearActive || !needBarCodeCamera
            ? new Text("")
            : new IconButton(
            icon: new Icon(Icons.photo_camera, color: buttonColor),
            disabledColor: buttonDisabledColor,
            onPressed: () => _scan()),
        !showClearButton
            ? new Text("")
            : new IconButton(
            icon: new Icon(Icons.clear, color: _clearActive ? buttonColor : buttonDisabledColor),
            disabledColor: buttonDisabledColor,
            onPressed: !_clearActive
                ? null
                : () {
              controller.clear();
            })
      ],
    );
  }

  /// Returns an [IconButton] suitable for an Action
  ///
  /// Put this inside your [buildDefaultAppBar] method!
  IconButton getSearchAction(BuildContext context) {
    return new IconButton(
        icon: new Icon(Icons.search),
        onPressed: () {
          beginSearch(context);
        });
  }

  /// Returns an AppBar based on the value of [_isSearching]
  AppBar build(BuildContext context) {
    return _isSearching ? buildSearchBar(context) : buildAppBar(context);
  }

  Future _scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() {
        controller.text = barcode;
        onType(barcode);
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {} else {}
    } on FormatException {} catch (e) {}
  }
}
