import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone/models/user.dart';
import 'package:instagram_clone/providers/user_provider.dart';
import 'package:instagram_clone/resources/firestore_methods.dart';
import 'package:instagram_clone/screens/comment_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:instagram_clone/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool isLikeAnimating = false;
  int commentLen = 0;
  OverlayEntry? entry;

  late TransformationController controller;
  TapDownDetails? tapDownDetails;

  late AnimationController animationController;
  Animation<Matrix4>? animation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = TransformationController();
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200))
          ..addListener(
            () => controller.value = animation!.value,
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              removeOverlay();
            }
          });
    getComments();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();
    animationController.dispose();
    super.dispose();
  }

  void getComments() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLen = snap.docs.length;
    } catch (e) {
      showSnackBar(e.toString(), context);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double minScale = 1;
    final double maxScale = 4;
    final User user = Provider.of<UserProvider>(context).getUser;
    return Container(
      color: mobileBackgroundColor,
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16)
                .copyWith(right: 0),
            child: Row(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.snap['profImage'],
                  imageBuilder: ((context, ImageProvider) => CircleAvatar(
                        backgroundImage: ImageProvider,
                        radius: 16,
                      )),
                  placeholder: (context, url) => Container(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.cover,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.snap['username'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shrinkWrap: true,
                          children: ['Delete']
                              .map(
                                (e) => InkWell(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (ctx) {
                                          return AlertDialog(
                                            title: Text('Are you Sure?'),
                                            content: Text(
                                                'Do you want to remove the item from the cart'),
                                            actions: [
                                              ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                  },
                                                  child: Text('No')),
                                              ElevatedButton(
                                                  onPressed: () {
                                                    FirestoreMethods()
                                                        .deletePost(widget
                                                            .snap['postId']);
                                                    Navigator.of(ctx).pop();
                                                  },
                                                  child: Text('Yes')),
                                            ],
                                          );
                                        });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    child: Text(e),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () async {
              await FirestoreMethods().likePost(
                  widget.snap['postId'], user.uid, widget.snap['likes']);
              setState(() {
                isLikeAnimating = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  width: double.infinity,
                  child: GestureDetector(
                    // onTapDown: (details) => tapDownDetails = details,
                    onTap: () {
                      // final position = tapDownDetails!.localPosition;
                      // final double scale = 3;
                      // final x = -position.dx * (scale - 1);
                      // final y = -position.dy * (scale - 1);
                      // final zoomed = Matrix4.identity()
                      //   ..translate(x, y)
                      //   ..scale(scale);

                      // final end = controller.value.isIdentity()
                      //     ? zoomed
                      //     : Matrix4.identity();
                      // // controller.value = end;

                      // animation = Matrix4Tween(
                      //   begin: controller.value,
                      //   end: end,
                      // ).animate(CurveTween(curve: Curves.easeOut)
                      //     .animate(animationController));

                      // animationController.forward(from: 0);
                    },
                    child: imageBuild(),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 105,
                    ),
                    isAnimating: isLikeAnimating,
                    duration: Duration(
                      milliseconds: 400,
                    ),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user.uid),
                smallLike: true,
                child: IconButton(
                    onPressed: () async {
                      await FirestoreMethods().likePost(widget.snap['postId'],
                          user.uid, widget.snap['likes']);
                      setState(() {
                        isLikeAnimating = true;
                      });
                    },
                    icon: widget.snap['likes'].contains(user.uid)
                        ? const Icon(
                            Icons.favorite,
                            size: 26,
                            color: Colors.red,
                            // size: Magnifier._borderRadius,
                            // color: primaryColor,
                          )
                        : const Icon(Icons.favorite_border_rounded)),
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CommentScreen(
                          snap: widget.snap,
                        ))),
                child: SvgPicture.asset(
                  'assets/comment.svg',
                  color: primaryColor,
                  height: 20,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              SvgPicture.asset(
                'assets/share.svg',
                color: primaryColor,
                height: 18,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                ),
              )
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(fontWeight: FontWeight.w800),
                  child: Text(
                    '${widget.snap['likes'].length} likes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: primaryColor),
                      children: [
                        TextSpan(
                          text: widget.snap['username'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '  ' + widget.snap['description'],
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                    child: Text(
                      'View all $commentLen comments',
                      style:
                          const TextStyle(fontSize: 16, color: secondaryColor),
                    ),
                  ),
                ),
                Container(
                  // padding:
                  //     const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                  child: Text(
                    DateFormat.yMMMMd()
                        .format(widget.snap['datePublished'].toDate()),
                    style: const TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget imageBuild() {
    return Builder(builder: (context) {
      return InteractiveViewer(
        clipBehavior: Clip.none,
        minScale: 1,
        maxScale: 4,
        transformationController: controller,
        panEnabled: false,
        onInteractionStart: (details) {
          if (details.pointerCount < 2) return;

          showOvelay(context);
        },
        onInteractionEnd: (details) {
          resetAnimation();
        },
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            child: CachedNetworkImage(
              imageUrl: widget.snap['postUrl'],
              placeholder: (context, url) => Container(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    });
  }

  void showOvelay(BuildContext context) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = MediaQuery.of(context).size;
    // final opacity = ((scale-1)/(maxScale-1)).clamp() ,
    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
                child: Container(
              color: Colors.black,
            )),
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              child: imageBuild(),
            ),
          ],
        );
      },
    );

    final overlay = Overlay.of(context)!;
    overlay.insert(entry!);
  }

  void resetAnimation() {
    // animation = Matrix4Tween(
    //                     begin: controller.value,
    //                     end: Matrix4.identity(),
    //                   ).animate(CurveTween(curve: Curves.easeOut)
    //                       .animate(animationController));

    animation = Matrix4Tween(
      begin: controller.value,
      end: Matrix4.identity(),
    ).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut));

    animationController.forward(from: 0);
  }

  void removeOverlay() {
    entry?.remove();
    entry = null;
  }
}
