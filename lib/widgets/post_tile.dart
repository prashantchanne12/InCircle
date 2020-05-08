import 'package:flutter/material.dart';
import 'package:in_circle/pages/post_screen.dart';
import 'package:in_circle/widgets/post.dart';

import 'custom_image.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: cachedNetworkImage(post.mediaUrl)),
      ),
    );
  }
}
