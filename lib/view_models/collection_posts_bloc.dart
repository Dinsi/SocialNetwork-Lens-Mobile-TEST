import 'package:aperture/locator.dart';
import 'package:aperture/models/collections/collection.dart';
import 'package:aperture/resources/repository.dart';

class CollectionPostsBloc {
  final int _collectionId;
  final _repository = locator<Repository>();

  CollectionPostsBloc(this._collectionId);

  Future<Collection> fetchCollection() {
    return _repository.fetchCollection(_collectionId);
  }
}