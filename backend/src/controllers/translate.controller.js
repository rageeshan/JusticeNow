const { translateWithGemini } = require('../services/translation.service');
const { sendSuccess, sendBadRequest } = require('../utils/response.util');

/**
 * POST /api/translate
 * Translate text to target language (Sinhala, Tamil, English)
 */
const translate = async (req, res, next) => {
  try {
    const { text, title, targetLang } = req.body;

    if (!text && !title) {
      return sendBadRequest(res, 'Text or title to translate is required');
    }

    if (!targetLang) {
      return sendBadRequest(res, 'targetLang is required (e.g. "si", "ta", "en")');
    }

    const results = {};

    if (title && title.trim() !== '') {
      results.translatedTitle = await translateWithGemini(title, targetLang);
    }

    if (text && text.trim() !== '') {
      results.translatedText = await translateWithGemini(text, targetLang);
    }

    results.targetLang = targetLang;

    return sendSuccess(res, results, 'Text translated successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  translate,
};
