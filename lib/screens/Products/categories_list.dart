import 'package:flutter/material.dart';

typedef void OpenCategoryCallback(String categoryName);

class CategoriesList extends StatelessWidget {
  const CategoriesList({this.categories, this.openCategory});

  final List<String> categories;
  final OpenCategoryCallback openCategory;

  @override
  Widget build(BuildContext context) {
    if (categories.length == 0) {
      return new Center(child: new CircularProgressIndicator());
    }

    return new ListView.builder(
      padding: kMaterialListPadding,
      itemCount: categories.length,
      itemBuilder: (BuildContext context, int index) {
        return new Row(children: [
          new Expanded(
              child: new Card(
            child: new MaterialButton(
              height: 60.0,
              child: new SizedBox(
                height: 30.0,
                width: MediaQuery.of(context).size.width,
                child: new FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  child: new Text(categories[index]),
                ),
              ),
              onPressed: () => openCategory(categories[index]),
            ),
          ))
        ]);
      },
    );
  }
}
