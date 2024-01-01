import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/widgets/post_card.dart';
import 'package:line_icons/line_icon.dart';
import 'package:local_auth/local_auth.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final LocalAuthentication auth;
  bool _supportState = false;
  late final ScrollController _scrollController;
  late List<Map<String, dynamic>> _posts;
  late bool _isLoading;
  late bool _hasMoreData;
  late DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  @override
  void initState() {
    super.initState();
    auth = LocalAuthentication();
    auth.isDeviceSupported().then((bool isSupported) => setState(() {
          _supportState = isSupported;
        }));

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _posts = [];
    _isLoading = false;
    _hasMoreData = true;
    _lastDocument = null;

    _loadMoreData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: SvgPicture.asset(
          'assets/ic_instagram.svg',
          color: primaryColor,
          height: 32,
        ),
        actions: [
          InkWell(
            onTap: () {},
            child: SvgPicture.asset(
              'assets/svg.svg',
              color: primaryColor,
              height: 30,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _posts.length) {
            return PostCard(
              snap: _posts[index],
            );
          } else {
            // Loading indicator when more data is being fetched
            return _isLoading
                ? Center(child: CircularProgressIndicator())
                : Container();
          }
        },
      ),
    );
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        _hasMoreData &&
        !_isLoading) {
      _loadMoreData();
    }
  }

  void _loadMoreData() async {
    setState(() {
      _isLoading = true;
    });

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('datePublished', descending: true)
        .limit(3);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      _posts.addAll(snapshot.docs.map((doc) => doc.data()));
    } else {
      _hasMoreData = false;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
