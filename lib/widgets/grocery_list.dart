import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        //get data from firebase
        'flutter-b92a2-default-rtdb.firebaseio.com',
        'shopping-lis.json');
    try {
      final resposne = await http.get(
          url); //get() or all other http methods will throw an error if something went wrong //for example if there is no internet connection

      //if firebase out of control for maintenance ex
      if (resposne.statusCode >= 400) {
        setState(() {
          _error = 'Failed to frtch data. Please try again later.';
        });
      }

      if (resposne.body == 'null') {
        //cuz firebase returns a null string
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(resposne.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading =
            false; //once i have my loaded items cuz i'm not loading anymore
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong!. Please try again later.';
      });
    }
  }
    void _addItem() async {
      final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(
          builder: (ctx) => const NewItem(),
        ),
      );
      if (newItem == null) {
        return;
      }

      setState(() {
        _groceryItems.add(newItem);
      });
    }

    void _removeItem(GroceryItem item) async {
      final index = _groceryItems.indexOf(item);
      setState(() {
        _groceryItems.remove(item); //delet from local list
      });

      final url = Uri.https(
          //get data from firebase
          'flutter-b92a2-default-rtdb.firebaseio.com',
          'shopping-lis/${item.id}.json'); //  /${item.id}  indecating to a specifec item to delete
      final response = await http.delete(url); //delete from firebase
      if (response.statusCode >= 400) {
        setState(() {
          _groceryItems.insert(index, item);
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      Widget content = const Center(child: Text('No items added yet.'));

      if (_isLoading) {
        content = const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (_groceryItems.isNotEmpty) {
        content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) => Dismissible(
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            key: ValueKey(_groceryItems[index].id),
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(
                _groceryItems[index].quantity.toString(),
              ),
            ),
          ),
        );
      }

      if (_error != null) {
        content = Center(child: Text(_error!));
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: content,
      );
    }
  }

