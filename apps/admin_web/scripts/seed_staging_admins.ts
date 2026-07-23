// Seed script: prints the admin documents that would be written to Firestore
// Run against real Firebase by providing credentials in .env.local
const roles = ['owner','moderator','finance','advertiser','polls','support','viewer','creator_manager','live_moderator','affiliate_manager'];
const permissions: Record<string,string[]> = {
  owner:['*'], moderator:['dashboard:read','moderation:read','moderation:write','video:read','video:write'],
  creator_manager:['dashboard:read','creator:read','creator:write','video:read','video:write'],
  finance:['dashboard:read','finance:read','finance:approve','wallet:read'],
  advertiser:['dashboard:read','ads:read','ads:write'], polls:['dashboard:read','polls:read','polls:write'],
  support:['dashboard:read','moderation:read'], live_moderator:['dashboard:read','live:read','live:moderate','moderation:read','moderation:write'],
  affiliate_manager:['dashboard:read','affiliate:read','affiliate:write'], viewer:['dashboard:read'],
};
console.log('\n=== STAGING ADMIN SEED DOCUMENTS ===');
roles.forEach(role => {
  const doc = { role, permissions: permissions[role], email: `${role}@yohpal.staging`, createdAt: new Date().toISOString() };
  console.log(`\nadmins/${role}-dev-001:`);
  console.log(JSON.stringify(doc, null, 2));
});
console.log('\n✓ Seed documents ready (connect Firebase to write)');
