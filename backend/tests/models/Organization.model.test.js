/**
 * Unit tests for Organization model
 */

require('../setup');
const mongoose = require('mongoose');
const Organization = require('../../src/models/Organization.model');
const User = require('../../src/models/User.model');

describe('Organization Model', () => {
  let testMember;

  beforeEach(async () => {
    testMember = await User.create({
      email: 'orgmember@example.com',
      role: 'lawyer',
      isVerified: true,
      approvalStatus: 'approved',
    });
  });

  it('should create an organization with valid required fields and defaults', async () => {
    const org = await Organization.create({
      name: 'Human Rights First',
      type: 'ngo',
    });

    expect(org._id).toBeDefined();
    expect(org.name).toBe('Human Rights First');
    expect(org.type).toBe('ngo');
    expect(org.isVerified).toBe(false);
    expect(org.isActive).toBe(true);
    expect(org.casesHandled).toBe(0);
    expect(org.description).toBe('');
    expect(org.specializations).toEqual([]);
    expect(org.createdAt).toBeInstanceOf(Date);
  });

  it('should reject organization without name', async () => {
    await expect(
      Organization.create({
        type: 'ngo',
      })
    ).rejects.toThrow(/Organization name is required/);
  });

  it('should reject organization without type', async () => {
    await expect(
      Organization.create({
        name: 'No Type Org',
      })
    ).rejects.toThrow();
  });

  it('should reject invalid organization type', async () => {
    await expect(
      Organization.create({
        name: 'Invalid Type Org',
        type: 'invalid_type_enum',
      })
    ).rejects.toThrow();
  });

  it('should accept all valid organization types', async () => {
    const validTypes = ['ngo', 'legal_firm', 'law_clinic', 'government_body', 'other'];
    for (const type of validTypes) {
      const org = await Organization.create({
        name: `Org ${type}`,
        type,
      });
      expect(org.type).toBe(type);
    }
  });

  it('should store specializations, contact, location, and members', async () => {
    const org = await Organization.create({
      name: 'Legal Aid Alliance',
      type: 'law_clinic',
      description: 'Providing free legal representation for victims.',
      specializations: ['arbitrary_detention', 'torture', 'right_to_fair_trial'],
      contact: {
        email: 'help@legalaid.org',
        phone: '+94112345678',
        website: 'https://legalaid.org',
        address: '123 Galle Road, Colombo',
      },
      location: {
        city: 'Colombo',
        state: 'Western',
        country: 'Sri Lanka',
      },
      isVerified: true,
      casesHandled: 15,
      members: [testMember._id],
    });

    expect(org.specializations).toHaveLength(3);
    expect(org.contact.email).toBe('help@legalaid.org');
    expect(org.location.city).toBe('Colombo');
    expect(org.members[0].toString()).toBe(testMember._id.toString());
    expect(org.casesHandled).toBe(15);
  });

  it('should reject invalid specializations enum', async () => {
    await expect(
      Organization.create({
        name: 'Bad Specialization',
        type: 'ngo',
        specializations: ['invalid_specialization'],
      })
    ).rejects.toThrow();
  });
});
