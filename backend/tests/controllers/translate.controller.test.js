/**
 * Unit tests for Translate Controller
 */

const { translate } = require('../../src/controllers/translate.controller');
const translationService = require('../../src/services/translation.service');

// Mock translation service
jest.mock('../../src/services/translation.service');

describe('Translate Controller', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      body: {},
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
    jest.clearAllMocks();
  });

  it('should return 400 if neither text nor title is provided', async () => {
    req.body = { targetLang: 'si' };

    await translate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        message: 'Text or title to translate is required',
      })
    );
  });

  it('should return 400 if targetLang is missing', async () => {
    req.body = { text: 'Some text' };

    await translate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        message: 'targetLang is required (e.g. "si", "ta", "en")',
      })
    );
  });

  it('should translate text and title successfully', async () => {
    req.body = {
      title: 'Original Title',
      text: 'Original incident description',
      targetLang: 'si',
    };

    translationService.translateWithGemini.mockImplementation(async (str) => {
      if (str === 'Original Title') return 'පරිවර්තිත මාතෘකාව';
      if (str === 'Original incident description') return 'පරිවර්තිත විස්තරය';
      return str;
    });

    await translate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: 'Text translated successfully',
      data: {
        translatedTitle: 'පරිවර්තිත මාතෘකාව',
        translatedText: 'පරිවර්තිත විස්තරය',
        targetLang: 'si',
      },
    });
  });

  it('should translate only text when title is not provided', async () => {
    req.body = {
      text: 'Just text to translate',
      targetLang: 'ta',
    };

    translationService.translateWithGemini.mockResolvedValue('மொழிபெயர்க்கப்பட்ட உரை');

    await translate(req, res, next);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      success: true,
      message: 'Text translated successfully',
      data: {
        translatedText: 'மொழிபெயர்க்கப்பட்ட உரை',
        targetLang: 'ta',
      },
    });
  });

  it('should pass unexpected service errors to next()', async () => {
    req.body = {
      text: 'Hello',
      targetLang: 'si',
    };

    const mockError = new Error('AI Translation Quota Exceeded');
    translationService.translateWithGemini.mockRejectedValue(mockError);

    await translate(req, res, next);

    expect(next).toHaveBeenCalledWith(mockError);
  });
});
