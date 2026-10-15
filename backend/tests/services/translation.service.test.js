/**
 * Unit tests for Translation Service (Gemini AI translation)
 */

const https = require('https');
const { EventEmitter } = require('events');
const { translateWithGemini } = require('../../src/services/translation.service');

describe('Translation Service', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv, GEMINI_API_KEY: 'test-gemini-key' };
    jest.restoreAllMocks();
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it('should throw an error if GEMINI_API_KEY is not configured', async () => {
    delete process.env.GEMINI_API_KEY;
    await expect(translateWithGemini('Hello', 'si')).rejects.toThrow(
      'GEMINI_API_KEY is not configured in backend environment'
    );
  });

  it('should return empty string if input text is empty or blank', async () => {
    const res1 = await translateWithGemini('', 'Sinhala');
    expect(res1).toBe('');

    const res2 = await translateWithGemini('   ', 'Sinhala');
    expect(res2).toBe('   ');

    const res3 = await translateWithGemini(null, 'Sinhala');
    expect(res3).toBe('');
  });

  it('should successfully translate text using Gemini API', async () => {
    const mockResponsePayload = JSON.stringify({
      candidates: [
        {
          content: {
            parts: [{ text: 'සාදරයෙන් පිළිගනිමු' }],
          },
        },
      ],
    });

    jest.spyOn(https, 'request').mockImplementation((options, callback) => {
      const res = new EventEmitter();
      res.statusCode = 200;

      process.nextTick(() => {
        callback(res);
        res.emit('data', Buffer.from(mockResponsePayload));
        res.emit('end');
      });

      const req = new EventEmitter();
      req.write = jest.fn();
      req.end = jest.fn();
      return req;
    });

    const result = await translateWithGemini('Welcome', 'si');
    expect(result).toBe('සාදරයෙන් පිළිගනිමු');
  });

  it('should support language alias mapping like ta -> Tamil and en -> English', async () => {
    const mockResponsePayload = JSON.stringify({
      candidates: [
        {
          content: {
            parts: [{ text: 'வணக்கம்' }],
          },
        },
      ],
    });

    let requestedPath = '';
    jest.spyOn(https, 'request').mockImplementation((options, callback) => {
      requestedPath = options.path;
      const res = new EventEmitter();
      res.statusCode = 200;

      process.nextTick(() => {
        callback(res);
        res.emit('data', Buffer.from(mockResponsePayload));
        res.emit('end');
      });

      const req = new EventEmitter();
      req.write = jest.fn();
      req.end = jest.fn();
      return req;
    });

    const result = await translateWithGemini('Hello', 'ta');
    expect(result).toBe('வணக்கம்');
    expect(requestedPath).toContain('gemini-3.5-flash-lite');
  });

  it('should fall back to next model when the first model returns non-200', async () => {
    let callCount = 0;
    jest.spyOn(https, 'request').mockImplementation((options, callback) => {
      callCount++;
      const res = new EventEmitter();

      if (callCount === 1) {
        res.statusCode = 503;
        process.nextTick(() => {
          callback(res);
          res.emit('data', Buffer.from(JSON.stringify({ error: { message: 'Service Unavailable' } })));
          res.emit('end');
        });
      } else {
        res.statusCode = 200;
        process.nextTick(() => {
          callback(res);
          res.emit('data', Buffer.from(JSON.stringify({
            candidates: [{ content: { parts: [{ text: 'Fallback Success' }] } }],
          })));
          res.emit('end');
        });
      }

      const req = new EventEmitter();
      req.write = jest.fn();
      req.end = jest.fn();
      return req;
    });

    const result = await translateWithGemini('Test text', 'English');
    expect(result).toBe('Fallback Success');
    expect(callCount).toBe(2);
  });

  it('should handle request network error and retry next model', async () => {
    let callCount = 0;
    jest.spyOn(https, 'request').mockImplementation((options, callback) => {
      callCount++;
      const req = new EventEmitter();
      req.write = jest.fn();
      req.end = jest.fn();

      if (callCount === 1) {
        process.nextTick(() => {
          req.emit('error', new Error('ECONNRESET'));
        });
      } else {
        const res = new EventEmitter();
        res.statusCode = 200;
        process.nextTick(() => {
          callback(res);
          res.emit('data', Buffer.from(JSON.stringify({
            candidates: [{ content: { parts: [{ text: 'Recovered' }] } }],
          })));
          res.emit('end');
        });
      }

      return req;
    });

    const result = await translateWithGemini('Retry test', 'Sinhala');
    expect(result).toBe('Recovered');
  });

  it('should throw error when all models fail', async () => {
    jest.spyOn(https, 'request').mockImplementation((options, callback) => {
      const res = new EventEmitter();
      res.statusCode = 500;
      process.nextTick(() => {
        callback(res);
        res.emit('data', Buffer.from(JSON.stringify({ error: { message: 'Model quota exceeded' } })));
        res.emit('end');
      });

      const req = new EventEmitter();
      req.write = jest.fn();
      req.end = jest.fn();
      return req;
    });

    await expect(translateWithGemini('Text', 'Sinhala')).rejects.toThrow('Model quota exceeded');
  });

  it('should handle invalid JSON in response', async () => {
    jest.spyOn(https, 'request').mockImplementation((options, callback) => {
      const res = new EventEmitter();
      res.statusCode = 200;
      process.nextTick(() => {
        callback(res);
        res.emit('data', Buffer.from('NOT_JSON_BODY'));
        res.emit('end');
      });

      const req = new EventEmitter();
      req.write = jest.fn();
      req.end = jest.fn();
      return req;
    });

    await expect(translateWithGemini('Text', 'Sinhala')).rejects.toThrow('Failed to parse Gemini response');
  });
});
