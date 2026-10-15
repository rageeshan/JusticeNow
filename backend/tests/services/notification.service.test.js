/**
 * Unit tests for notification service
 * Tests the placeholder notification functions
 */

const {
  sendPushNotification,
  notifyCaseUpdate,
  sendWelcomeNotification,
} = require('../../src/services/notification.service');

describe('Notification Service', () => {
  let consoleSpy;

  beforeEach(() => {
    consoleSpy = jest.spyOn(console, 'log').mockImplementation();
  });

  afterEach(() => {
    consoleSpy.mockRestore();
  });

  describe('sendPushNotification', () => {
    it('should log push notification details', async () => {
      await sendPushNotification('fcm-token-123', 'Alert', 'Test body');

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('fcm-token-123')
      );
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Alert')
      );
    });

    it('should not throw with empty data', async () => {
      await expect(
        sendPushNotification('token', 'Title', 'Body', {})
      ).resolves.not.toThrow();
    });
  });

  describe('notifyCaseUpdate', () => {
    it('should log case update notification', async () => {
      const mockCase = { referenceNumber: 'JN-2026-00001' };
      await notifyCaseUpdate(mockCase, 'investigating', 'Now under investigation');

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('JN-2026-00001')
      );
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('investigating')
      );
    });
  });

  describe('sendWelcomeNotification', () => {
    it('should log welcome for aliased user', async () => {
      await sendWelcomeNotification({ alias: 'Citizen-ABC' });

      expect(consoleSpy).toningHaveBeenCalledWith(
        expect.stringContai('Citizen-ABC')
      );
    });

    it('should log welcome for email user', async () => {
      await sendWelcomeNotification({ email: 'user@test.com' });

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('user@test.com')
      );
    });
  });
});
