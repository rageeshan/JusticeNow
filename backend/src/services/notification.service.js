/**
 * Notification service placeholder
 * 
 * In a production system, this would integrate with:
 * - Firebase Cloud Messaging (FCM) for push notifications
 * - SendGrid / Mailgun for email
 * - Twilio for SMS
 */

/**
 * Send a push notification to a user's device
 * @param {string} fcmToken - Device FCM token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Optional extra data payload
 */
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  // TODO: Implement FCM integration
  console.log(`[Notification] Push → ${fcmToken}: ${title} — ${body}`);
};

/**
 * Notify a case reporter of a status update
 * @param {object} caseDoc - The case document
 * @param {string} newStatus - The new status
 * @param {string} publicMessage - The public-facing message
 */
const notifyCaseUpdate = async (caseDoc, newStatus, publicMessage) => {
  // TODO: Retrieve reporter's FCM token from device registration
  // TODO: Send FCM push notification
  console.log(
    `[Notification] Case ${caseDoc.referenceNumber} status changed to ${newStatus}: ${publicMessage}`
  );
};

/**
 * Send a welcome notification to a new user
 */
const sendWelcomeNotification = async (user) => {
  console.log(`[Notification] Welcome to JusticeNow, ${user.alias || user.email}!`);
};

module.exports = { sendPushNotification, notifyCaseUpdate, sendWelcomeNotification };
