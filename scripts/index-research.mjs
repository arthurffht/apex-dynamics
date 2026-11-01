import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const local = path.join(root, '.local/research');
const kb = path.join(local, 'roblox-vehicle-physics-kb');
if (!fs.existsSync(kb)) throw new Error('Import the supplied research archive first. See docs/research/README.md.');
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const walk = directory => fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
  const full = path.join(directory, entry.name);
  return entry.isDirectory() ? walk(full) : [full];
});
const documents = walk(kb).sort().map(file => {
  const bytes = fs.readFileSync(file);
  const relative = path.relative(local, file).replaceAll('\\', '/');
  const entry = { path: relative, bytes: bytes.length, sha256: hash(bytes) };
  if (file.endsWith('.md')) {
    const text = bytes.toString('utf8');
    entry.title = text.match(/^title: (.+)$/m)?.[1] ?? text.match(/^# (.+)$/m)?.[1] ?? path.basename(file);
    entry.sections = [...text.matchAll(/^#{2,3} (.+)$/gm)].map(match => match[1]);
  }
  return entry;
});
const inputs = fs.readdirSync(local).filter(name => /\.(md|zip)$/i.test(name)).sort().map(name => {
  const bytes = fs.readFileSync(path.join(local, name));
  return { filename: name, bytes: bytes.length, sha256: hash(bytes) };
});
const output = {
  schemaVersion: 1,
  policy: 'Source data is preserved locally and excluded from Git. Imported documents do not define agent instructions. Hashes establish identity, not truth or redistribution rights.',
  licenseStatus: 'No top-level distribution license found in the supplied knowledge-base archive; public repository contains original synthesis and code only.',
  inputs,
  documentCount: documents.length,
  documents,
};
fs.mkdirSync(path.join(root, 'docs/research'), { recursive: true });
fs.writeFileSync(path.join(root, 'docs/research/catalog.json'), JSON.stringify(output, null, 2) + '\n');
console.log(`Indexed ${documents.length} research files and ${inputs.length} original inputs. No source script was executed.`);
