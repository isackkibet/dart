"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateSearchKeywords = generateSearchKeywords;
function generateSearchKeywords(input) {
    const rawParts = [];
    for (const key of [
        'title',
        'caption',
        'displayName',
        'username',
        'bio',
        'businessName',
        'name',
        'category',
    ]) {
        const value = input[key];
        if (typeof value === 'string')
            rawParts.push(value);
    }
    for (const key of ['hashtags', 'tags']) {
        const value = input[key];
        if (Array.isArray(value)) {
            rawParts.push(...value.filter((v) => typeof v === 'string'));
        }
    }
    const fullText = rawParts.join(' ').toLowerCase();
    const tokens = fullText
        .replace(/[^a-z0-9\s#@]/gi, ' ')
        .split(/\s+/)
        .map((t) => t.trim().replace(/^#|^@/, ''))
        .filter((t) => t.length >= 2);
    return Array.from(new Set(tokens)).slice(0, 100);
}
