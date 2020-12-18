const functions = require('firebase-functions');
const admin = require('firebase-admin');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });


exports.onCreateFollower = functions
.firestore
.document("/followers/{profileId}/userFollowers/{currentUserId}")
.onCreate(async(snapshot,context)=>{
    const profileId = context.params.profileId;
    const currentUserId = context.params.currentUserId;

    console.log('followerCreated');


    const timelineRef = admin.firestore()
    .collection('timeline')
    .doc(currentUserId)
    .collection('timelinePost');

    const postsForTimelineRef = admin.firestore()
    .collection('posts')
    .doc(profileId)
    .collection('userPosts');


    const querySnapshot = await postsForTimelineRef.get();
    
    querySnapshot.forEach(doc=>{

        if(doc.exists){
            const postId = doc.id;
            const postData = doc.data;

            timelineRef.doc(postId).set({postData});
        }
        

    });

   
});