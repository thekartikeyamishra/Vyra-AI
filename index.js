/**
 * VYRA PRODUCTION BACKEND (Lazy Init Version)
 * Fixes "Timeout after 10000" deployment errors by initializing
 * logic only when the function is actually CALLED, not when deployed.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");
const { GoogleGenerativeAI } = require("@google/generative-ai");
require("dotenv").config();

// --- GLOBAL VARS (Lazy Loaded) ---
// We do NOT initialize them here. We wait until the function runs.
let dbInstance = null;

// --- CONSTANTS ---
const FREE_DAILY_LIMIT = 5;
const PREMIUM_DAILY_LIMIT = 100;

/**
 * HELPER: GET DATABASE (Safe Init)
 * Ensures admin.initializeApp() is only called when needed.
 */
function getDb() {
  if (!dbInstance) {
    // Check if Firebase is already initialized to avoid "Duplicate App" errors
    if (admin.apps.length === 0) {
      admin.initializeApp();
    }
    dbInstance = admin.firestore();
  }
  return dbInstance;
}

/**
 * HELPER: GET OPENAI CLIENT
 */
const getOpenAIClient = () => {
  if (!process.env.OPENAI_API_KEY) {
    throw new HttpsError("internal", "Server Error: Missing OpenAI Key");
  }
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
};

/**
 * HELPER: GET GEMINI CLIENT
 */
const getGeminiClient = () => {
  if (!process.env.GEMINI_API_KEY) {
    throw new HttpsError("internal", "Server Error: Missing Gemini Key");
  }
  return new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
};

/**
 * CORE FUNCTION: GENERATE IMAGE
 */
exports.generateImage = onCall(
  {
    timeoutSeconds: 300, 
    memory: "512MiB",
    maxInstances: 10,
  },
  async (request) => {
    // --- 1. INITIALIZE (Happens now, not during deploy) ---
    const db = getDb();

    // --- 2. SECURITY CHECK ---
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be logged in to generate images."
      );
    }

    const uid = request.auth.uid;
    const { prompt, style, isPremium } = request.data;

    // Validation
    if (!prompt || typeof prompt !== "string" || prompt.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Prompt cannot be empty.");
    }
    if (prompt.length > 500) {
      throw new HttpsError("invalid-argument", "Prompt is too long.");
    }

    // --- 3. CHECK LIMITS ---
    const userRef = db.collection("users").doc(uid);
    const today = new Date().toISOString().split("T")[0];
    
    const userSnap = await userRef.get();
    const userData = userSnap.data() || {};
    
    let currentDailyCount = 0;
    if (userData.lastGenerationDate === today) {
      currentDailyCount = userData.dailyGenerationCount || 0;
    }

    const limit = isPremium ? PREMIUM_DAILY_LIMIT : FREE_DAILY_LIMIT;

    if (currentDailyCount >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        `Daily limit of ${limit} reached.`
      );
    }

    try {
      // --- 4. GEMINI AGENT ---
      let optimizedPrompt = prompt;
      try {
        const genAI = getGeminiClient();
        const model = genAI.getGenerativeModel({ model: "gemini-pro" });
        const agentPrompt = `
          Rewrite this art prompt for DALL-E 3 to be detailed and artistic.
          Original: "${prompt}"
          Style: "${style}"
          Keep it under 40 words. Output ONLY the prompt.
        `;
        const result = await model.generateContent(agentPrompt);
        const text = result.response.text();
        if (text) optimizedPrompt = text.replace(/^["']|["']$/g, '').trim();
      } catch (e) {
        console.warn("Gemini skipped:", e.message);
      }

      // --- 5. OPENAI GENERATION ---
      const openai = getOpenAIClient();
      const imageResponse = await openai.images.generate({
        model: "dall-e-3",
        prompt: optimizedPrompt,
        n: 1,
        size: "1024x1024",
        quality: "standard",
        response_format: "url",
      });

      const imageUrl = imageResponse.data[0].url;
      if (!imageUrl) throw new Error("No image returned.");

      // --- 6. SAVE DATA (Transaction) ---
      await db.runTransaction(async (t) => {
        const freshUserSnap = await t.get(userRef);
        const freshData = freshUserSnap.data() || {};
        
        let freshCount = 0;
        if (freshData.lastGenerationDate === today) {
          freshCount = freshData.dailyGenerationCount || 0;
        }

        t.set(userRef, {
            dailyGenerationCount: freshCount + 1,
            lastGenerationDate: today,
            totalGenerations: admin.firestore.FieldValue.increment(1),
            xp: admin.firestore.FieldValue.increment(10)
        }, { merge: true });

        const genRef = db.collection("generations").doc();
        t.set(genRef, {
            uid: uid,
            originalPrompt: prompt,
            optimizedPrompt: optimizedPrompt,
            style: style,
            imageUrl: imageUrl,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            isPublic: false
        });
      });

      return {
        success: true,
        imageUrl: imageUrl,
        optimizedPrompt: optimizedPrompt
      };

    } catch (error) {
      console.error("Gen Error:", error);
      throw new HttpsError("internal", "Generation failed. Please try again.");
    }
  }
);