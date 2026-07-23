import { resolveCreatorTier } from './creatorRevenueConfig';

describe('resolveCreatorTier', () => {
  it('returns null below 100 viewers', () => {
    expect(resolveCreatorTier(99)).toBeNull();
    expect(resolveCreatorTier(0)).toBeNull();
    expect(resolveCreatorTier(1)).toBeNull();
  });

  it('returns bronze at exactly 100 viewers', () => {
    const tier = resolveCreatorTier(100);
    expect(tier?.tier).toBe('bronze');
    expect(tier?.creatorSharePercent).toBe(20);
  });

  it('returns bronze between 100–499 viewers', () => {
    expect(resolveCreatorTier(101)?.tier).toBe('bronze');
    expect(resolveCreatorTier(499)?.tier).toBe('bronze');
  });

  it('returns silver at exactly 500 viewers', () => {
    const tier = resolveCreatorTier(500);
    expect(tier?.tier).toBe('silver');
    expect(tier?.creatorSharePercent).toBe(25);
  });

  it('returns gold at exactly 2000 viewers', () => {
    const tier = resolveCreatorTier(2000);
    expect(tier?.tier).toBe('gold');
    expect(tier?.creatorSharePercent).toBe(30);
  });

  it('returns diamond at exactly 10000 viewers', () => {
    const tier = resolveCreatorTier(10000);
    expect(tier?.tier).toBe('diamond');
    expect(tier?.creatorSharePercent).toBe(35);
  });

  it('returns elite at exactly 50000 viewers', () => {
    const tier = resolveCreatorTier(50000);
    expect(tier?.tier).toBe('elite');
    expect(tier?.creatorSharePercent).toBe(40);
  });

  it('returns elite above 50000 viewers', () => {
    expect(resolveCreatorTier(100000)?.tier).toBe('elite');
  });

  it('resolves the highest eligible tier (not lowest)', () => {
    // 2500 viewers should be gold, not bronze or silver
    expect(resolveCreatorTier(2500)?.tier).toBe('gold');
    expect(resolveCreatorTier(15000)?.tier).toBe('diamond');
  });
});
