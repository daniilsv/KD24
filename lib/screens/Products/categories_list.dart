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
              height: 50.0,
              child: new ListTile(
                title: new Text(
                  categories[index],
                  style: new TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
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
