const https = require('https');

const GEMINI_MODELS = ['gemini-3.5-flash-lite', 'gemini-3.8-flash', 'gemini-3.5-flash'];

const LANGUAGE_NAMES = {
  si: 'Sinhala',
  sinhala: 'Sinhala',
  ta: 'Tamil',
  tamil: 'Tamil',
  en: 'English',
  english: 'English',
};

/**
 * Translate text into Sinhala, Tamil, or English using Gemini AI
 * @param {string} text - text to translate
 * @param {string} targetLang - 'si' | 'ta' | 'en' | 'Sinhala' | 'Tamil' | 'English'
 * @returns {Promise<string>} translated text
 */
const translateWithGemini = async (text, targetLang = 'English') => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured in backend environment');
  }

  if (!text || text.trim() === '') {
    return text || '';
  }

  const langName = LANGUAGE_NAMES[targetLang.toLowerCase()] || targetLang;

  const prompt = `You are an expert translator specializing in human rights, law, and incident reporting in Sri Lanka.
Translate the following incident report text accurately and fluently into ${langName}.
Maintain proper legal phrasing and accurate local place/person names.
IMPORTANT: Return ONLY the direct translated text. Do NOT add notes, explanations, quotes, or markdown wrappers.

Text to translate:
"""
${text}
"""`;

  const requestBody = JSON.stringify({
    contents: [
      {
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 2048,
    },
  });

  let lastError = null;

  for (const model of GEMINI_MODELS) {
    try {
      const translated = await new Promise((resolve, reject) => {
        const req = https.request(
          {
            hostname: 'generativelanguage.googleapis.com',
            path: `/v1beta/models/${model}:generateContent?key=${apiKey}`,
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Content-Length': Buffer.byteLength(requestBody),
            },
          },
          (res) => {
            let responseData = '';
            res.on('data', (chunk) => {
              responseData += chunk;
            });

            res.on('end', () => {
              try {
                const json = JSON.parse(responseData);
                if (res.statusCode >= 200 && res.statusCode < 300) {
                  const out =
                    json.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || text;
                  resolve(out);
                } else {
                  const errMsg =
                    json.error?.message || `Gemini API returned status ${res.statusCode}`;
                  reject(new Error(errMsg));
                }
              } catch (e) {
                reject(new Error(`Failed to parse Gemini response: ${e.message}`));
              }
            });
          }
        );

        req.on('error', (err) => {
          reject(err);
        });

        req.write(requestBody);
        req.end();
      });

      if (translated) return translated;
    } catch (err) {
      lastError = err;
      // continue to next model
    }
  }

  throw lastError || new Error('All Gemini translation models failed');
};

module.exports = {
  translateWithGemini,
};
