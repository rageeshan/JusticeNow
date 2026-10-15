/**
 * Unit tests for Evidence model
 */

require('../setup');
const mongoose = require('mongoose');
const Evidence = require('../../src/models/Evidence.model');
const User = require('../../src/models/User.model');
const Case = require('../../src/models/Case.model');

describe('Evidence Model', () => {
  let user, caseDoc;

  beforeEach(async () => {
    user = await User.create({ alias: 'Citizen-EV', role: 'citizen' });
    caseDoc = await Case.create({
      referenceNumber: 'JN-2026-EV001',
      title: 'Evidence Case',
      description: 'For evidence testing.',
      category: 'other',
      incidentDate: new Date(),
      reportedBy: user._id,
    });
  });

  it('should create evidence with required fields', async () => {
    const evidence = await Evidence.create({
      case: caseDoc._id,
      uploadedBy: user._id,
      fileType: 'image',
      originalName: 'photo.jpg',
      storedName: 'abc-123.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 204800,
      storagePath: '/uploads/test/abc-123.jpg',
    });

    expect(evidence.fileType).toBe('image');
    expect(evidence.originalName).toBe('photo.jpg');
    expect(evidence.isSealed).toBe(false);
    expect(evidence.isDeleted).toBe(false);
    expect(evidence.description).toBe('');
  });

  it('should reject evidence without case reference', async () => {
    await expect(
      Evidence.create({
        uploadedBy: user._id,
        fileType: 'document',
        originalName: 'report.pdf',
        storedName: 'def-456.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 100000,
        storagePath: '/uploads/test/def-456.pdf',
      })
    ).rejects.toThrow();
  });

  it('should reject invalid fileType', async () => {
    await expect(
      Evidence.create({
        case: caseDoc._id,
        uploadedBy: user._id,
        fileType: 'spreadsheet', // not in enum
        originalName: 'data.xlsx',
        storedName: 'ghi-789.xlsx',
        mimeType: 'application/vnd.ms-excel',
        sizeBytes: 50000,
        storagePath: '/uploads/test/ghi-789.xlsx',
      })
    ).rejects.toThrow();
  });

  it('should accept all valid fileTypes', async () => {
    const types = ['image', 'video', 'audio', 'document', 'other'];
    for (const fileType of types) {
      const evidence = await Evidence.create({
        case: caseDoc._id,
        uploadedBy: user._id,
        fileType,
        originalName: `file.${fileType}`,
        storedName: `stored-${fileType}`,
        mimeType: 'application/octet-stream',
        sizeBytes: 1000,
        storagePath: `/uploads/test/stored-${fileType}`,
      });
      expect(evidence.fileType).toBe(fileType);
    }
  });

  it('should store custody log entries', async () => {
    const evidence = await Evidence.create({
      case: caseDoc._id,
      uploadedBy: user._id,
      fileType: 'document',
      originalName: 'doc.pdf',
      storedName: 'custody-test.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 30000,
      storagePath: '/uploads/test/custody-test.pdf',
      custodyLog: [
        { action: 'uploaded', performedBy: user._id, note: 'Initial upload' },
      ],
    });

    expect(evidence.custodyLog).toHaveLength(1);
    expect(evidence.custodyLog[0].action).toBe('uploaded');

    // Add more custody events
    evidence.custodyLog.push({ action: 'reviewed', performedBy: user._id, note: 'Officer reviewed' });
    await evidence.save();

    const fetched = await Evidence.findById(evidence._id);
    expect(fetched.custodyLog).toHaveLength(2);
    expect(fetched.custodyLog[1].action).toBe('reviewed');
  });

  it('should store integrity hash', async () => {
    const hash = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';
    const evidence = await Evidence.create({
      case: caseDoc._id,
      uploadedBy: user._id,
      fileType: 'image',
      originalName: 'hashed.png',
      storedName: 'hashed-img.png',
      mimeType: 'image/png',
      sizeBytes: 500000,
      storagePath: '/uploads/test/hashed-img.png',
      integrityHash: hash,
    });

    expect(evidence.integrityHash).toBe(hash);
  });
});
