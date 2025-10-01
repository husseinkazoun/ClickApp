import { writeFileSync, mkdirSync } from 'node:fs';
mkdirSync('docs', { recursive: true });
const html = `<!DOCTYPE html><html><head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=brand.html">
<link rel="canonical" href="brand.html">
<title>Click’App</title>
</head><body>
If not redirected, <a href="brand.html">open the brand page</a>.
</body></html>`;
writeFileSync('docs/index.html', html);
console.log('✓ docs/index.html redirect → brand.html');
