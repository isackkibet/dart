import fs from 'fs';
import path from 'path';

const appDir = path.join(process.cwd(), 'app');

function collectPages(dir: string, prefix = ''): string[] {
  const results: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      const segment = entry.name.startsWith('(') ? '' : `/${entry.name}`;
      results.push(...collectPages(path.join(dir, entry.name), prefix + segment));
    } else if (entry.name === 'page.tsx') {
      results.push(prefix || '/');
    } else if (entry.name === 'route.ts') {
      results.push(`[API] ${prefix}`);
    }
  }
  return results;
}

const routes = collectPages(appDir).sort();
const pages = routes.filter(r => !r.startsWith('[API]'));
const apis  = routes.filter(r =>  r.startsWith('[API]'));

console.log(`\n=== ROUTE INVENTORY ===`);
console.log(`Admin Pages : ${pages.length}`);
console.log(`API Routes  : ${apis.length}`);
console.log(`\n--- Pages ---`);
pages.forEach(p => console.log(` ${p}`));
console.log(`\n--- API Routes ---`);
apis.forEach(a => console.log(` ${a}`));
console.log(`\n✓ Inventory complete`);
