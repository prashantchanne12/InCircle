const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// ---------- OnCreate Follower ------------
exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async(snapshot, context) => {
          console.log("Follower Created!", snapshot.id);
          const userId = context.params.userId;
          const followerId = context.params.followerId;

          // 1) Get the followed user's posts ref
          const followedUserPostRef = admin
                                         .firestore()
                                         .collection('posts')
                                         .doc(userId)
                                         .collection('userPosts');

          // 2) Get the following user's timeline ref
          const timelinePostRef = admin
                                     .firestore()
                                     .collection('timeline')
                                     .doc(followerId)
                                     .collection('timelinePosts');


          // 3) Get the followed user's posts
          const querySnapshot = await followedUserPostRef.get();

          // 4) Add each user post to following user's timeline
          querySnapshot.forEach( doc => {

                if(doc.exists){

                    const postId = doc.id
                    const postData = doc.data()

                    timelinePostRef.doc(postId).set(postData);
                }

          });

    });

// ---------- OnDelete Follower ------------
exports.onDeleteFollower = functions.firestore
           .document("/followers/{userId}/userFollowers/{followerId}")
           .onDelete(async(snapshot, context) => {

           console.log("Follower Deleted!", snapshot.id);

           const userId = context.params.userId;
           const followerId = context.params.followerId;


          // Get the following user's timeline ref
          const timelinePostRef = admin
                                     .firestore()
                                     .collection('timeline')
                                     .doc(followerId)
                                     .collection('timelinePosts')
                                     .where('ownerId', '==', userId);


          const querySnapshot = await timelinePostRef.get();
          querySnapshot.forEach( doc => {

                if(doc.exists){
                    doc.ref.delete();
                }

          });

       });

// ---------- OnCreate Post ------------

// when post is created we want to add that post to timeline of each follower
exports.onCreatePost = functions.firestore
        .document("/posts/{userId}/userPosts/{postId}")
        .onCreate(async(snapshot, context) => {

            const postCreated = snapshot.data(); // newly created post data
            const userId = context.params.userId;
            const postId = context.params.postId;

            // 1) Get all the followers of the user who made post
            const userFollowersRef = admin.firestore()
                    .collection('followers')
                    .doc(userId)
                    .collection('userFollowers');

            const querySnapshot = await userFollowersRef.get();

            // 2) Add new post to each followers timeline
            querySnapshot.forEach((doc) => {

                followerId = doc.id;

                admin
                    .firestore()
                    .collection('timeline')
                    .doc(followerId)
                    .collection('timelinePosts')
                    .doc(postId)
                    .set(postCreated)


            });

        });

// ---------- OnUpdate Post ------------

// If post is update ex. Likes
exports.onUpdatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onUpdate(async (change, context) => {

        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;


        const userFollowersRef = admin.firestore()
                        .collection('followers')
                        .doc(userId)
                        .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();


        // 2) Update each post in each followers timeline
        querySnapshot.forEach((doc) => {

            followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {

                    if(doc.exists){
                        doc.ref.update(
                            postUpdated
                        );
                    }

                });


        });

    });



// ---------- OnDelete Post ------------

// If post is deleted by owner
exports.onDeletePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onDelete(async (snapshot, context) => {

        const userId = context.params.userId;
        const postId = context.params.postId;


        const userFollowersRef = admin.firestore()
                        .collection('followers')
                        .doc(userId)
                        .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();


        // 2) Update each post in each followers timeline
        querySnapshot.forEach((doc) => {

            followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {

                    if(doc.exists){
                        doc.ref.delete();
                    }

                });
        });
});

// ---------- Push Notification ------------
exports.onCreateActivityFeedItem = functions.firestore
  .document("/feed/{userId}/feedItems/{activityFeedItem}")
  .onCreate(async (snapshot, context) => {
    console.log("Activity Feed Item Created", snapshot.data());

    // 1) Get user connected to the feed
    const userId = context.params.userId;

    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();

    // 2) Once we have user, check if they have a notification token; send notification, if they have a token
    const androidNotificationToken = doc.data().androidNotificationToken;
    const createdActivityFeedItem = snapshot.data();
    if (androidNotificationToken) {
      sendNotification(androidNotificationToken, createdActivityFeedItem);
    } else {
      console.log("No token for user, cannot send notification");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      // 3) switch body value based off of notification type
      switch (activityFeedItem.type) {
        case "comment":
          body = `${activityFeedItem.username} replied: ${
            activityFeedItem.commentData
          }`;
          break;
        case "like":
          body = `${activityFeedItem.username} liked your post`;
          break;
        case "follow":
          body = `${activityFeedItem.username} started following you`;
          break;
        default:
          break;
      }

      // 4) Create message for push notification
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: userId }
      };

      // 5) Send message with admin.messaging()
      admin
        .messaging()
        .send(message)
        .then(response => {
          // Response is a message ID string
          console.log("Successfully sent message", response);
        })
        .catch(error => {
          console.log("Error sending message", error);
        });
    }
  });


// /messages/102868147774937939400106585613342559026009/chats/K804BAknzFWzCrIENCfy

// ---------- Push Notification Chat Message ------------
exports.onMessageSent = functions.firestore
  .document("/messages/{chatId}/chats/{docId}")
  .onCreate(async (snapshot, context) => {
    console.log("Activity Feed Item Created", snapshot.data());

    const chatId = context.params.userId;
    const docId = context.params.docId;

    const chatMessageItem = snapshot.data();

    if(chatMessageItem.isSeen == false){

     // 1) Getting receiver userId and textBody
        const userId = chatMessageItem.receiverId;

        const userRef = admin.firestore().doc(`users/${userId}`);
        const doc = await userRef.get();

        // 2) Once we have user, check if they have a notification token; send notification, if they have a token
        const androidNotificationToken = doc.data().androidNotificationToken;


        if (androidNotificationToken) {
          sendNotification(androidNotificationToken, chatMessageItem);
        } else {
          console.log("No token for user, cannot send notification");
        }

    }

    function sendNotification(androidNotificationToken, chatMessageItem) {

     const body = chatMessageItem.text;

      // 3) Create message for push notification
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: chatMessageItem.receiverId }
      };

      // 4) Send message with admin.messaging()
      admin
        .messaging()
        .send(message)
        .then(response => {
          // Response is a message ID string
          console.log("Successfully sent message", response);
        })
        .catch(error => {
          console.log("Error sending message", error);
        });
    }
  });



// ------- Update User Status (Online/Offline) ------------

const firestore = functions.firestore;

exports.onUserStatusChange = functions.database.ref('/status/{userId}')
	.onUpdate(async (change, context) => {

		var db = admin.firestore();


		//const usersRef = firestore.document('/users/' + event.params.userId);
		const usersRef = db.collection("users");
		var snapShot = change.after;

		return change.after.ref.once('value')
			.then(statusSnap => snapShot.val())
			.then(status => {
				if (status === 'offline'){
					usersRef
						.doc(context.params.userId)
						.update({
							online: false,
							last_active: Date(Date.now())
						}, {merge: true});
				}
			})
	});

//	        const postUpdated = change.after.data();
/*
 // Use of Date.now() function
  var d = Date(Date.now());

  // Converting the number of millisecond in date string
  a = d.toString()
*/