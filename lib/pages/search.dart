import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:flutter_icons/flutter_icons.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  String username;
  Future<QuerySnapshot> result;
  TextEditingController editingController = TextEditingController();

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: TextFormField(
          controller: editingController,
          onFieldSubmitted: (val) {
            handleSearch(val);
            //print(val);
          },
          onChanged: (val) {
            username = val;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search for other people',
            hintStyle: TextStyle(
              color: Theme.of(context).primaryColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: EdgeInsets.only(left: 10.0),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Feather.search,
              size: 30.0,
            ),
            onPressed: () {
              handleSearch(username);
            },
            color: Colors.deepPurple,
          ),
        ],
      ),
      body: result == null ? buildNoContent(context) : buildContent(),
    );
  }

  //methods.....................
  handleSearch(String query) {
    Future<QuerySnapshot> searchResult = Firestore.instance
        .collection('user')
        .where("username", isGreaterThanOrEqualTo: query.trim())
        .getDocuments();
    setState(() {
      result = searchResult;
    });
  }

  FutureBuilder<QuerySnapshot> buildContent() {
    return FutureBuilder<QuerySnapshot>(
        future: result,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<SearchResultTile> searchResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            searchResults.add(SearchResultTile(
              context: context,
              user: user,
            ));
          });

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              shrinkWrap: true,
              children: searchResults,
            ),
          );
        });
  }

  Container buildNoContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15.0),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Image.asset(
              'assets/images/search.png',
              height: MediaQuery.of(context).size.height * 0.3,
            ),
          ],
        ),
      ),
    );
  }
}

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({Key key, @required this.context, this.user})
      : super(key: key);

  final BuildContext context;
  final User user;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).primaryColor.withOpacity(0.5),
      ),
      padding: EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Profile(
              profileID: user.id,
            );
          }));
        },
        child: ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            ),
            title: Text(
              user.username,
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            )),
      ),
    );
  }
}
