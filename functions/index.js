const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Cloud Function that sends push notifications
 * Triggered when a new notification document is created in Firestore
 */
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notificationData = snapshot.data();
      
      if (!notificationData) {
        console.log('No notification data found');
        return null;
      }
      
      const { tokens, title, body, type, data = {} } = notificationData;
      
      if (!tokens || !tokens.length) {
        console.log('No tokens to send to');
        return null;
      }
      
      // Prepare the message
      const message = {
        notification: {
          title,
          body,
        },
        data: {
          ...data,
          type,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens,
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              badge: 1,
              sound: 'default',
            },
          },
        },
      };
      
      // Send the message
      const response = await admin.messaging().sendMulticast(message);
      
      console.log(`${response.successCount} messages were sent successfully`);
      
      // If there are failures, log them
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push({ token: tokens[idx], error: resp.error });
          }
        });
        console.log('List of failed tokens:', failedTokens);
      }
      
      return { success: true, sentCount: response.successCount };
    } catch (error) {
      console.error('Error sending notification:', error);
      return { error: error.message };
    }
  });

/**
 * Cloud Function to notify users about new announcements
 * Triggered when a new announcement is created
 */
exports.notifyNewAnnouncement = functions.firestore
  .document('announcements/{announcementId}')
  .onCreate(async (snapshot, context) => {
    try {
      const announcement = snapshot.data();
      
      if (!announcement) {
        console.log('No announcement data found');
        return null;
      }
      
      // Only send notifications for important announcements
      if (!announcement.isImportant) {
        console.log('Not an important announcement, skipping notification');
        return null;
      }
      
      // Get all users
      const usersSnapshot = await admin.firestore().collection('users').get();
      const tokens = [];
      
      // Collect all user tokens
      usersSnapshot.forEach(doc => {
        const user = doc.data();
        if (user.fcmTokens && user.fcmTokens.length) {
          tokens.push(...user.fcmTokens);
        }
      });
      
      if (!tokens.length) {
        console.log('No tokens to send to');
        return null;
      }
      
      // Send a message to devices subscribed to the "announcements" topic
      const message = {
        notification: {
          title: 'Important Announcement',
          body: announcement.name,
        },
        data: {
          announcementId: context.params.announcementId,
          type: 'announcement',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              badge: 1,
              sound: 'default',
            },
          },
        },
        topic: 'announcements',
      };
      
      // Send the message
      const response = await admin.messaging().send(message);
      console.log('Successfully sent announcement notification:', response);
      
      return { success: true };
    } catch (error) {
      console.error('Error sending announcement notification:', error);
      return { error: error.message };
    }
  }); 