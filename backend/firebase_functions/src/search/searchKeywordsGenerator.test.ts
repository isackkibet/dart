import { generateSearchKeywords } from './searchKeywordsGenerator';

describe('generateSearchKeywords', () => {
  it('tokenizes normal text fields', () => {
    const result = generateSearchKeywords({
      title: 'Best Live Cooking Show',
      caption: 'Fresh nyama choma today!',
    });
    expect(result).toContain('best');
    expect(result).toContain('live');
    expect(result).toContain('cooking');
    expect(result).toContain('nyama');
  });

  it('tokenizes hashtags and tags arrays', () => {
    const result = generateSearchKeywords({
      hashtags: ['#YohPal', '#LiveCommerce'],
      tags: ['Kenya', 'Food'],
    });
    expect(result).toContain('yohpal');
    expect(result).toContain('livecommerce');
    expect(result).toContain('kenya');
    expect(result).toContain('food');
  });

  it('deduplicates keywords', () => {
    const result = generateSearchKeywords({ title: 'Live Live Live' });
    expect(result.filter((x) => x === 'live')).toHaveLength(1);
  });

  it('ignores very short tokens (length < 2)', () => {
    const result = generateSearchKeywords({ title: 'a b ai tv' });
    expect(result).not.toContain('a');
    expect(result).not.toContain('b');
    expect(result).toContain('ai');
    expect(result).toContain('tv');
  });

  it('strips leading # and @ from tokens', () => {
    const result = generateSearchKeywords({ hashtags: ['#nairobi', '@creator'] });
    expect(result).toContain('nairobi');
    expect(result).toContain('creator');
    expect(result).not.toContain('#nairobi');
    expect(result).not.toContain('@creator');
  });

  it('returns empty array for empty input', () => {
    const result = generateSearchKeywords({});
    expect(result).toHaveLength(0);
  });

  it('caps output at 100 keywords', () => {
    const longTitle = Array.from({ length: 200 }, (_, i) => `word${i}`).join(' ');
    const result = generateSearchKeywords({ title: longTitle });
    expect(result.length).toBeLessThanOrEqual(100);
  });

  it('handles multiple text fields combined', () => {
    const result = generateSearchKeywords({
      displayName: 'Jane Wanjiru',
      username: 'janecooks',
      bio: 'Nairobi food creator',
    });
    expect(result).toContain('jane');
    expect(result).toContain('wanjiru');
    expect(result).toContain('janecooks');
    expect(result).toContain('nairobi');
  });
});
