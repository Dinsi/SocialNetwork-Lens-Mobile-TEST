import 'dart:async';

import 'package:aperture/models/post.dart';
import 'package:aperture/network/api.dart';
import 'package:aperture/screens/detailed_post_screen.dart';
import 'package:aperture/utils/post_shared_functions.dart';
import 'package:aperture/widgets/posts/image_container.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:synchronized/synchronized.dart';
import 'package:transparent_image/transparent_image.dart';

const double _iconSideSize = 45.0;
const double _defaultHeight = 55.0;

class BasicPost extends StatefulWidget {
  final Post post;

  const BasicPost({Key key, @required this.post}) : super(key: key);

  @override
  _BasicPostState createState() => _BasicPostState(this.post.votes, this.post.commentsLength, this.post.userVote);
}

class _BasicPostState extends State<BasicPost> {
  _BasicPostState(this._numberOfVotes, this._numberOfComments, this._currentVote);

  int _numberOfVotes;
  int _numberOfComments;
  int _currentVote;
  bool _downIconColor;
  bool _upIconColor;
  final Lock _lock = Lock();

  @override
  void initState() {
    super.initState();
    _setIconColors();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ImageContainer(
            imageUrl: widget.post.image,
            imageHeight: widget.post.height,
            imageWidth: widget.post.width,
            onTap: () => _toDetailedPostScreen(toComments: false),
            onDoubleTap: () => _upvoteOrRemove(),
          ),
          Material(
            elevation: 5.0,
            child: Container(
              height: _defaultHeight,
              child: Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: Theme.of(context).iconTheme.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          height: _iconSideSize,
                          width: _iconSideSize,
                          color: Colors.grey[300],
                          child: (widget.post.user.avatar == null
                              ? Image.asset(
                                  'assets/img/user_placeholder.png',
                                )
                              : FadeInImage.memoryNetwork(
                                  placeholder: kTransparentImage,
                                  image: widget.post.user.avatar,
                                )),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Material(
                            child: InkWell(
                              onTap: () => _upvoteOrRemove(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      FontAwesomeIcons.arrowAltCircleUp,
                                      color: _upIconColor
                                          ? Colors.blue
                                          : Colors.grey[600],
                                    ),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text(
                                      nFormatter(_numberOfVotes.toDouble(), 0),
                                      style: votesTextStyle(
                                          _upIconColor ? Colors.blue : null),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Material(
                            child: InkWell(
                              onTap: () => _downvoteOrRemove(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Icon(
                                  FontAwesomeIcons.arrowAltCircleDown,
                                  color: _downIconColor
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          FlatButton.icon(
                            color: Colors.transparent,
                            icon: Icon(
                              FontAwesomeIcons.commentAlt,
                              size: 18.0,
                              color: Colors.grey[600],
                            ),
                            label: Text(
                              _numberOfComments.toString(),
                              style: votesTextStyle(),
                            ),
                            onPressed: () =>
                                _toDetailedPostScreen(toComments: true),
                          ),
                        ],
                      ),
                      PopupMenuButton<int>(
                        onSelected: (int result) {},
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<int>>[
                              const PopupMenuItem<int>(
                                value: 1,
                                child: Text("1"),
                              ),
                              const PopupMenuItem<int>(
                                value: 2,
                                child: Text("2"),
                              ),
                              const PopupMenuItem<int>(
                                value: 3,
                                child: Text("3"),
                              ),
                              const PopupMenuItem<int>(
                                value: 4,
                                child: Text("4"),
                              ),
                            ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _toDetailedPostScreen({@required bool toComments}) async {
    Map<String, int> data = await Navigator.of(context).push(MaterialPageRoute<Map<String, int>>(
        builder: (BuildContext context) => DetailedPostScreen(
            post: widget.post,
            votes: _numberOfVotes,
            currentVote: _currentVote,
            comments: _numberOfComments,
            toComments: toComments)));

    if (_numberOfVotes != data["votes"]) {
      _numberOfVotes = data["votes"];
      _currentVote = data["currentVote"];
      _setIconColors();
      if (_numberOfComments == data["comments"]) {
        setState(() {});
      }
    }

    if (_numberOfComments != data["comments"]) {
      setState(() {
        _numberOfComments = data["comments"];
      });
    }
  }

  Future _downvoteOrRemove() async {
    await _lock.synchronized(() async {
      if (_currentVote == -1) {
        setState(() {
          _downIconColor = false;
          _numberOfVotes++;
        });

        int result = await Api.removeVote(widget.post.id);
        if (!mounted) {
          return;
        }

        if (result == 0) {
          setState(() {
            _currentVote = 0;
          });
        } else {
          setState(() {
            _downIconColor = true;
            _numberOfVotes--;
          });
          /*TODO place dialog here*/
        }
        return;
      }

      setState(() {
        _upIconColor = false;
        _downIconColor = true;
        _currentVote == 1 ? _numberOfVotes -= 2 : _numberOfVotes--;
      });

      int result = await Api.downVote(widget.post.id);
      if (!mounted) {
        return;
      }

      if (result == 0) {
        setState(() {
          _currentVote = -1;
        });
      } else {
        setState(() {
          _upIconColor = true;
          _downIconColor = false;
          _currentVote == 1 ? _numberOfVotes += 2 : _numberOfVotes++;
        }); /*TODO place dialog here*/
      }
    });
  }

  Future _upvoteOrRemove() async {
    await _lock.synchronized(() async {
      if (_currentVote == 1) {
        setState(() {
          _upIconColor = false;
          _numberOfVotes--;
        });

        int result = await Api.removeVote(widget.post.id);
        if (!mounted) {
          return;
        }

        if (result == 0) {
          setState(() => _currentVote = 0);
        } else {
          setState(() {
            _upIconColor = true;
            _numberOfVotes++;
          });
          /*TODO place dialog here*/
        }
        return;
      }
      if (!mounted) {
        return;
      }

      setState(() {
        _upIconColor = true;
        _downIconColor = false;
        _currentVote == -1 ? _numberOfVotes += 2 : _numberOfVotes++;
      });

      int result = await Api.upVote(widget.post.id);
      if (!mounted) {
        return;
      }

      if (result == 0) {
        setState(() {
          _currentVote = 1;
        });
      } else {
        setState(() {
          _upIconColor = false;
          _downIconColor = true;
          _currentVote == -1 ? _numberOfVotes -= 2 : _numberOfVotes--;
        });
        /*TODO place dialog here*/
      }
    });
  }

  void _setIconColors() {
    switch (_currentVote) {
      case 0:
        _downIconColor = false;
        _upIconColor = false;
        break;
      case 1:
        _downIconColor = false;
        _upIconColor = true;
        break;
      case -1:
        _downIconColor = true;
        _upIconColor = false;
        break;
      default:
    }
  }
}
