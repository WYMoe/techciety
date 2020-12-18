class User {

  final String username;
  final String id;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;
  User({this.bio,this.id,this.username,this.displayName,this.email,this.photoUrl});

  factory User.fromDocument(doc){
      return User(
         id: doc['id'],
      email: doc['email'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      );

  }

}
