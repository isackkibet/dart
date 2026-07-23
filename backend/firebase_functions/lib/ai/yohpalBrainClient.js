"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.callYohPalBrain = callYohPalBrain;
async function callYohPalBrain(prompt) {
    const apiUrl = process.env.YOHPAL_BRAIN_API_URL;
    const apiKey = process.env.YOHPAL_BRAIN_API_KEY;
    if (!apiUrl || !apiKey) {
        return {
            provider: 'mock',
            text: `AI provider not configured. Prompt received: ${prompt}`,
        };
    }
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 25000);
    try {
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${apiKey}`,
            },
            body: JSON.stringify({
                prompt,
                product: 'yohpal_live_ai_creator_studio',
            }),
            signal: controller.signal,
        });
        if (!response.ok) {
            throw new Error(`YohPal Brain failed: ${response.status}`);
        }
        const body = await response.json();
        return {
            provider: 'yohpal_brain',
            text: String(body.text ?? body.output ?? JSON.stringify(body)),
        };
    }
    finally {
        clearTimeout(timeout);
    }
}
