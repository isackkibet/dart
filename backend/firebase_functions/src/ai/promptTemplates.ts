export function buildPrompt(type: string, input: Record<string, unknown>): string {
  switch (type) {
    case 'captions':
      return `Generate 5 short-video captions in ${input.language || 'English'}. Make them catchy, clear, and creator-friendly.`;
    case 'hooks':
      return `Generate 10 viral opening hooks for a short video about: ${input.topic || 'general lifestyle content'}.`;
    case 'hashtags':
      return `Generate 20 hashtags for this caption: ${input.caption || ''}. Mix broad, niche, and trending-style hashtags.`;
    case 'viral_score':
      return `Score this short video idea from 0 to 100 and explain why. Title: ${input.title || ''} Description: ${input.description || ''}`;
    case 'thumbnail_ideas':
      return `Generate 8 thumbnail ideas for a short video. Topic: ${input.topic || ''}.`;
    case 'trim_suggestions':
      return `Suggest highlight trim points for this short video description: ${input.description || ''}.`;
    default:
      throw new Error(`Unsupported AI job type: ${type}`);
  }
}
