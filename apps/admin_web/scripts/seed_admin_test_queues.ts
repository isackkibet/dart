// Describes seed data that would be written to each queue collection
const queues = [
  { collection: 'walletPayouts',     status: 'pending',  count: 5, note: 'finance/payouts queue' },
  { collection: 'moderationReports', status: 'open',     count: 5, note: 'moderation queue' },
  { collection: 'videos',            status: 'active',   count: 5, note: 'videos queue' },
  { collection: 'creatorProfiles',   status: 'active',   count: 5, note: 'creators queue' },
  { collection: 'liveSessions',      status: 'ended',    count: 5, note: 'live queue' },
  { collection: 'adCampaigns',       status: 'pending',  count: 5, note: 'advertiser/campaigns queue' },
  { collection: 'polls',             status: 'active',   count: 5, note: 'polls/manage queue' },
  { collection: 'aiVideoJobs',       status: 'queued',   count: 5, note: 'ai-jobs queue' },
  { collection: 'affiliateEarnings', status: 'pending',  count: 5, note: 'affiliate/earnings queue' },
  { collection: 'chatMessages',      reportStatus: 'reported', count: 5, note: 'chat/moderation queue' },
  { collection: 'chargebacks',       status: 'open',     count: 5, note: 'finance/chargebacks queue' },
];
console.log('\n=== STAGING QUEUE SEED PLAN ===');
queues.forEach(q => {
  console.log(`\n${q.collection} (${q.note}):`);
  for (let i = 1; i <= q.count; i++) {
    const doc: Record<string,unknown> = { id: `seed-${i}`, ...(q.status?{status:q.status}:{}), ...(q.reportStatus?{reportStatus:q.reportStatus}:{}), createdAt: new Date(Date.now() - i * 3600000).toISOString(), amount: 1000 * i, currency: 'KES' };
    console.log(`  doc ${i}: ${JSON.stringify(doc)}`);
  }
});
console.log('\n✓ Queue seed plan ready (connect Firebase to write)');
