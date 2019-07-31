import 'package:aperture/models/comment.dart';
import 'package:aperture/ui/core/base_view.dart';
import 'package:aperture/ui/shared/basic_post.dart';
import 'package:aperture/ui/shared/comment_tile.dart';
import 'package:aperture/ui/shared/description_text.dart';
import 'package:aperture/ui/shared/loading_lists/no_scroll_loading_list_view.dart';
import 'package:aperture/view_models/detailed_post.dart';
import 'package:aperture/view_models/shared/basic_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

const double _iconSideSize = 60.0;
const double _defaultHeight = 75.0;

class DetailedPostScreen extends StatelessWidget {
  final bool toComments;
  final BasicPostModel basicPostModel;

  const DetailedPostScreen({
    @required this.toComments,
    @required this.basicPostModel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Theme(
          data: Theme.of(context).copyWith(
            iconTheme:
                Theme.of(context).iconTheme.copyWith(color: Colors.grey[600]),
          ),
          child: ChangeNotifierBaseView<DetailedPostModel>(
            onModelReady: (model) {
              model.init(toComments, basicPostModel);
            },
            builder: (context, model, _) {
              return RefreshIndicator(
                onRefresh: model.onRefresh,
                child: NotificationListener<ScrollNotification>(
                  onNotification: model.onNotification,
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: SingleChildScrollView(
                          controller: model.scrollController,
                          child: Column(
                            key: model.columnKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildWidgetList(context, model),
                          ),
                        ),
                      ),
                      _buildNewCommentContainer(context, model),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWidgetList(BuildContext context, DetailedPostModel model) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 12.0, right: 12.0),
        child: Container(
          height: _defaultHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildUserRow(context, model),
              _buildTopActionButtons(model),
            ],
          ),
        ),
      ),
      DescriptionText(
        text: model.post.description,
        withHashtags: true,
      ),
      ChangeNotifierProvider.value(
        value: basicPostModel,
        child: BasicPost(delegatingModel: true),
      ),
      _buildCommentSection(model)
    ];
  }

  Widget _buildUserRow(BuildContext context, DetailedPostModel model) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            height: _iconSideSize,
            width: _iconSideSize,
            color: Colors.grey[300],
            child: Stack(
              children: <Widget>[
                Center(
                  child: (model.post.user.avatar == null
                      ? Image.asset(
                          'assets/img/user_placeholder.png',
                        )
                      : FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: model.post.user.avatar,
                        )),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.white24,
                    onTap: () => model.navigateToUserProfile(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            model.post.user.name,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActionButtons(DetailedPostModel model) {
    // TODO Implement action buttons
    return SizedBox(
      width: 50.0,
      height: _defaultHeight - 20.0,
      child: Placeholder(),
    );
  }

  Widget _buildCommentSection(DetailedPostModel model) {
    return NoScrollLoadingListView<Comment>(
      model: model,
      widgetAdapter: (ObjectKey key, Comment comment) => CommentTile(
        key: key,
        comment: comment,
        onPressed: model.navigateToUserProfile,
      ),
    );
  }

  Widget _buildNewCommentContainer(
      BuildContext context, DetailedPostModel model) {
    return Container(
      child: Column(
        children: <Widget>[
          Divider(height: 10.0, color: Colors.black45),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 9.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: model.commentTextController,
                    focusNode: model.commentFocusNode,
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1024),
                    ],
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 5.0,
                        horizontal: 2.0,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    width: 100.0,
                    child: FlatButton(
                      child: Text(
                        'Publish',
                        style: TextStyle(
                          fontSize: 19.0,
                          color: model.state == DetailedPostViewState.Idle
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                      onPressed: model.state == DetailedPostViewState.Idle
                          ? () => model.onPressed(context)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
