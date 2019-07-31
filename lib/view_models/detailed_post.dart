import 'dart:async';
import 'dart:collection';

import 'package:aperture/models/comment.dart';
import 'package:aperture/models/post.dart';
import 'package:aperture/models/users/compact_user.dart';
import 'package:aperture/router.dart';
import 'package:aperture/view_models/core/base_model.dart';
import 'package:aperture/view_models/core/mixins/base_feed.dart';
import 'package:aperture/view_models/shared/basic_post.dart';
import 'package:flutter/material.dart';

const _commentLimit = 10;

enum DetailedPostViewState { Idle, Publishing }

class DetailedPostModel extends StateModel<DetailedPostViewState>
    with BaseFeedMixin<Comment> {
  DetailedPostModel() : super(DetailedPostViewState.Idle);

  BasicPostModel _basicPostModel;

  String _nextLink;
  bool _toComments;

  GlobalKey _columnKey = GlobalKey();
  ScrollController _scrollController = ScrollController();
  TextEditingController _commentTextController = TextEditingController();
  FocusNode _commentFocusNode = FocusNode();
  double _initialHeight;

  // * Init Functions
  void init(bool toComments, BasicPostModel model) {
    // Set toComments
    _toComments = toComments;
    if (_toComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateInitialHeight();
      });
    }

    // Delegate model
    _basicPostModel = model;
  }

  /////////////////////////////////////////////////////////////
  // * Dispose
  @override
  void dispose() {
    super.dispose();
    _scrollController?.dispose();
    _commentFocusNode.dispose();
    _commentTextController.dispose();
  }

  /////////////////////////////////////////////////////////////
  // * Mixin calls
  @override
  Future<void> fetch(bool refresh) async {
    if (refresh) {
      // Must reload post data and its respective comments
      // ! index 0 => updated post data
      // ! index 1 => updated comments data

      List<Future> futures = List<Future>(2);

      futures[0] =
          _basicPostModel.repository.fetchSinglePost(_basicPostModel.post.id);
      futures[1] = _basicPostModel.repository
          .fetchComments(_commentLimit, _basicPostModel.post.id, null);

      List fetchedData = await Future.wait(futures);

      _basicPostModel.setPost(fetchedData[0] as Post);
      _updateComments(fetchedData[1]);
    } else {
      dynamic fetchedData = await _basicPostModel.repository
          .fetchComments(_commentLimit, _basicPostModel.post.id, _nextLink);

      _updateComments(fetchedData);
    }
  }

  @override
  void afterInitialFetch(double circularIndicatorHeight) {
    if (_toComments) {
      _initialHeight = _initialHeight - circularIndicatorHeight;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (listSubject.hasValue) {
          if (_scrollController.position.maxScrollExtent <= _initialHeight) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          } else {
            _scrollController.jumpTo(_initialHeight);
          }
        }
      });
    }
  }

  /////////////////////////////////////////////////////////////
  // * on__ Functions
  Future onPressed(BuildContext context) async {
    setState(DetailedPostViewState.Publishing);

    FocusScope.of(context).requestFocus(FocusNode());
    String newComment = _commentTextController.text.trim();
    _commentTextController.clear();

    Comment newCommentObj = await _basicPostModel.repository.postComment(
        _basicPostModel.post.id, newComment); // TODO assuming result is valid

    if (!listSubject.isClosed) {
      listSubject.sink.add(listSubject.value..insert(0, newCommentObj));
    }

    _basicPostModel.post.commentsLength++;

    // Propagating changes
    _basicPostModel.notifyListeners();
    setState(DetailedPostViewState.Idle);
  }

  /////////////////////////////////////////////////////////////
  // * Navigator Functions
  void navigateToUserProfile(BuildContext context, [CompactUser user]) {
    // TODO navigateToUserProfile
    Navigator.of(context).pushNamed(
      RouteName.userProfile,
      arguments: user != null ? user.id : _basicPostModel.post.user.id,
    );
  }

  /////////////////////////////////////////////////////////////
  // * Private Functions
  void _updateComments(dynamic commentData) {
    UnmodifiableListView<Comment> comments;

    if (commentData is Map) {
      _nextLink = commentData["nextLink"];

      if (_nextLink == null) {
        existsNext = false;
      }

      if (!listSubject.hasValue) {
        comments = UnmodifiableListView<Comment>(
            commentData["comments"] as List<Comment>);
      } else {
        comments = UnmodifiableListView<Comment>(
          List<Comment>.from(listSubject.value)
            ..addAll(commentData["comments"] as List<Comment>),
        );
      }
    }

    if (!listSubject.isClosed) {
      listSubject.sink.add(comments);
    }
  }

  void _calculateInitialHeight() {
    final RenderBox columnRenderBox =
        _columnKey.currentContext.findRenderObject();
    _initialHeight = columnRenderBox.size.height;
  }

  /////////////////////////////////////////////////////////////
  // * Getters
  Post get post => _basicPostModel.post;
  VoidCallback get onUpvoteOrRemove => _basicPostModel.onUpvoteOrRemove;
  VoidCallback get onDownvoteOrRemove => _basicPostModel.onDownvoteOrRemove;

  GlobalKey get columnKey => _columnKey;
  ScrollController get scrollController => _scrollController;
  TextEditingController get commentTextController => _commentTextController;
  FocusNode get commentFocusNode => _commentFocusNode;
}