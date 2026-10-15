/**
 * Unit tests for Advertisement model
 */

require('../setup');
const mongoose = require('mongoose');
const Advertisement = require('../../src/models/Advertisement.model');
const User = require('../../src/models/User.model');

describe('Advertisement Model', () => {
  let lawyer;

  beforeEach(async () => {
    lawyer = await User.create({
      email: 'ad_lawyer@test.com',
      role: 'lawyer',
      isVerified: true,
      approvalStatus: 'approved',
    });
  });

  it('should create advertisement with required fields and defaults', async () => {
    const ad = await Advertisement.create({
      lawyer: lawyer._id,
      imageUrl: 'https://example.com/banner.png',
    });

    expect(ad._id).toBeDefined();
    expect(ad.lawyer.toString()).toBe(lawyer._id.toString());
    expect(ad.imageUrl).toBe('https://example.com/banner.png');
    expect(ad.lawyerName).toBe('Attorney at Law');
    expect(ad.lawyerCourtNumber).toBe('');
    expect(ad.lawyerDistrict).toBe('');
    expect(ad.lawyerProvince).toBe('');
    expect(ad.caption).toBe('');
    expect(ad.isActive).toBe(true);
    expect(ad.createdAt).toBeInstanceOf(Date);
  });

  it('should reject advertisement without lawyer reference', async () => {
    await expect(
      Advertisement.create({
        imageUrl: 'https://example.com/banner.png',
      })
    ).rejects.toThrow();
  });

  it('should reject advertisement without imageUrl', async () => {
    await expect(
      Advertisement.create({
        lawyer: lawyer._id,
      })
    ).rejects.toThrow(/Post image is required/);
  });

  it('should store custom details and trim strings', async () => {
    const ad = await Advertisement.create({
      lawyer: lawyer._id,
      imageUrl: 'https://example.com/lawyer-post.png',
      lawyerName: '  Attorney Kamala Perera  ',
      lawyerCourtNumber: '  SC/1234/2020  ',
      lawyerDistrict: 'Colombo',
      lawyerProvince: 'Western',
      caption: '  Available for human rights consultations  ',
      isActive: false,
    });

    expect(ad.lawyerName).toBe('Attorney Kamala Perera');
    expect(ad.lawyerCourtNumber).toBe('SC/1234/2020');
    expect(ad.caption).toBe('Available for human rights consultations');
    expect(ad.isActive).toBe(false);
  });
});
