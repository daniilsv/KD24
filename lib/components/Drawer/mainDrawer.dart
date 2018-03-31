import 'package:flutter/material.dart';
import 'package:kd24_shop_spy/routes.dart';
import 'package:kd24_shop_spy/services/utils.dart';

class DrawerMain extends StatefulWidget {
  GlobalKey<ScaffoldState> scaffoldKey;

  DrawerMain({Key key, GlobalKey<ScaffoldState> this.scaffoldKey})
      : super(key: key);

  @override
  _DrawerMainState createState() => new _DrawerMainState();
}

class _DrawerMainState extends State<DrawerMain> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _drawerContentsOpacity;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _drawerContentsOpacity = new CurvedAnimation(
      parent: new ReverseAnimation(_controller),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: new Column(
        children: <Widget>[
          new DrawerHeader(child: null),
          new MediaQuery.removePadding(
            context: context,
            // DrawerHeader consumes top MediaQuery padding.
            removeTop: true,
            child: new Expanded(
              child: new ListView(
                padding: const EdgeInsets.only(top: 8.0),
                children: <Widget>[
                  new Stack(
                    children: <Widget>[
                      new FadeTransition(
                        opacity: _drawerContentsOpacity,
                        child: new Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new ListTile(
                              leading: const Icon(Icons.home),
                              title: new Text('Магазины'),
                              onTap: () {
                                Routes.backTo(context, "/shops");
                              },
                            ),
                            new ListTile(
                              leading: const Icon(Icons.send),
                              title: new Text('Отправить изменения'),
                              onTap: () =>
                                  Utils
                                      .sendProducts(context)
                                      .then((String res) {
                                    Utils.showInSnackBar(
                                        widget.scaffoldKey, res);
                                  }),
                            ),
                            new ListTile(
                              leading: const Icon(Icons.settings),
                              title: new Text('Настройки'),
                              onTap: () =>
                                  Routes.navigateTo(context, "/settings"),
                            ),
                            new ListTile(
                              leading: const Icon(Icons.exit_to_app),
                              title: new Text('Выход'),
                              onTap: () => Utils.logout(context),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
