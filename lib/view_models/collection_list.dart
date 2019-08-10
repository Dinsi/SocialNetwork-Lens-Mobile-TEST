import 'dart:async';

import 'package:aperture/models/users/user.dart';
import 'package:aperture/router.dart';
import 'package:aperture/ui/utils/shortcuts.dart';
import 'package:aperture/view_models/append_to_collection_bloc.dart';
import 'package:aperture/models/collections/collection.dart';
import 'package:aperture/models/collections/compact_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:rxdart/subjects.dart';

class CollectionListModel extends AppendToCollectionModel {
  bool _isAddToCollection;
  final _canPopController = PublishSubject<bool>();

  //////////////////////////////////////////////////////////////////////

  final scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController _newCollectionController;

  //////////////////////////////////////////////////////////////////////
  // * Init
  void init(bool addToCollection, int postId) {
    _isAddToCollection = addToCollection;
    protPostId = postId;
  }

  //////////////////////////////////////////////////////////////////////
  // * Dispose
  void dipose(bool addToCollection, int postId) {
    _canPopController.close();
  }

  //////////////////////////////////////////////////////////////////////
  // * Public Functions
  bool existsInCollection(int index) {
    return appInfo.currentUser.collections[index].posts.contains(protPostId);
  }

  //////////////////////////////////////////////////////////////////////

  Future<void> onCollectionTap(BuildContext context, int index) async {
    CompactCollection targetCollection = appInfo.currentUser.collections[index];

    if (_isAddToCollection) {
      if (!existsInCollection(index)) {
        Collection result = await updateCollection(index);
        if (result != null) {
          //TODO only covers valid response
          Navigator.of(context).pop(targetCollection.name);
        }
      } else {
        showInSnackBar(
          context,
          scaffoldKey,
          '${targetCollection.name} already contains current post',
        );
      }

      return;
    }

    Navigator.of(context).pushNamed(
      RouteName.collectionPosts,
      arguments: {
        'collId': targetCollection.id,
        'collName': targetCollection.name,
      },
    );
  }

  //////////////////////////////////////////////////////////////////////

  Future<void> showNewCollectionDialog(BuildContext context) async {
    if (_newCollectionController == null) {
      _newCollectionController = TextEditingController();
    }

    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create new collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Name (max. 64):'),
            const SizedBox(
              height: 8.0,
            ),
            TextField(
              controller: _newCollectionController,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(64)],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(12.0),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop<bool>(false),
          ),
          FlatButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop<bool>(true),
          )
        ],
      ),
    );

    if (dialogResult == null || dialogResult == false) {
      return;
    }

    // Prevent user from using the back button
    _canPopController.sink.add(false);

    // Validations
    final newCollectionName = _newCollectionController.text.trim();
    _newCollectionController.clear();

    if (newCollectionName.isEmpty) {
      showInSnackBar(context, scaffoldKey, 'A collection must have a name');
      return;
    }

    // Send new collection name to the server
    final newCollection = await repository.postNewCollection(newCollectionName);
    if (newCollection != null) {
      User user = appInfo.currentUser;

      final newCompactCollection =
          CompactCollection.fromJson(newCollection.toJson());

      user.collections.add(newCompactCollection);
      await appInfo.updateUser(user);

      // If the objective is to add a post to a collection, add it to the newly created collection
      if (_isAddToCollection) {
        final updatedCollection =
            await updateCollection(user.collections.length - 1);

        if (updatedCollection != null) {
          Navigator.of(context).pop(newCollectionName);
        } else {
          showInSnackBar(context, scaffoldKey,
              'Server error: could not add post to collection');
        }
      } else {
        // Grant access to back button
        _canPopController.sink.add(true);
        showInSnackBar(context, scaffoldKey,
            'Collection ($newCollectionName) created');
      }
    } else {
      showInSnackBar(context, scaffoldKey,
          'Server error: could not create new collection');
    }
  }

  //////////////////////////////////////////////////////////////////////
  // * Getters
  bool get isAddToCollection => _isAddToCollection;
  int get postId => protPostId;

  Stream<bool> get canPopStream => _canPopController.stream;
}