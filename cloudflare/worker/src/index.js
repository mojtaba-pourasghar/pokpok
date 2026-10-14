/**
 * POPO asset gateway: serves the app's illustrations, sounds and narrator voice from a private
 * R2 bucket.
 *
 * Public content lives under popo/<version>/… . Paths are versioned, so every file is immutable
 * and is cached for a year at the edge and on the device; only packs.json (the pack index) is
 * short-lived. The bucket itself stays private: this Worker is the only way in, GET/HEAD only.
 *
 * Licensed content that must not be public goes under popo-private/<version>/… and is served
 * only with a signed URL (?exp=<unix seconds>&sig=<hex HMAC-SHA256 of "<path>:<exp>">) made with
 * the SIGNING_KEY secret. The app never holds that key; a URL would have to be minted by a
 * server you control (none ships with this project). Without SIGNING_KEY, private paths are 404.
 */

const PUBLIC_PREFIX = 'popo/';
const PRIVATE_PREFIX = 'popo-private/';
const TYPES = {
  mp3: 'audio/mpeg',
  m4a: 'audio/mp4',
  ogg: 'audio/ogg',
  webp: 'image/webp',
  png: 'image/png',
  jpg: 'image/jpeg',
  svg: 'image/svg+xml',
  json: 'application/json; charset=utf-8',
};

function corsHeaders(env) {
  return {
    'Access-Control-Allow-Origin': env.ALLOWED_ORIGIN || '*',
    'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
    'Access-Control-Allow-Headers': 'Range, If-None-Match',
    'Access-Control-Expose-Headers': 'ETag, Content-Length, Content-Range',
    'Access-Control-Max-Age': '86400',
  };
}

const hex = (buf) => [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');

async function validSignature(env, key, url) {
  if (!env.SIGNING_KEY) return false;
  const exp = Number(url.searchParams.get('exp'));
  const sig = url.searchParams.get('sig') || '';
  if (!Number.isFinite(exp) || exp < Date.now() / 1000) return false;
  const k = await crypto.subtle.importKey('raw', new TextEncoder().encode(env.SIGNING_KEY), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const expected = hex(await crypto.subtle.sign('HMAC', k, new TextEncoder().encode(`${key}:${exp}`)));
  if (expected.length !== sig.length) return false;
  let diff = 0;
  for (let i = 0; i < sig.length; i++) diff |= expected.charCodeAt(i) ^ sig.charCodeAt(i);
  return diff === 0;
}

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(env) });
    }
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405, headers: { Allow: 'GET, HEAD, OPTIONS' } });
    }

    const url = new URL(request.url);
    const key = decodeURIComponent(url.pathname.replace(/^\/+/, ''));
    if (key.includes('..')) return new Response('Not Found', { status: 404 });
    const isPrivate = key.startsWith(PRIVATE_PREFIX);
    if (!key.startsWith(PUBLIC_PREFIX) && !isPrivate) return new Response('Not Found', { status: 404 });
    if (isPrivate && !(await validSignature(env, key, url))) return new Response('Not Found', { status: 404 });

    // Private responses are never put in the shared edge cache.
    const cache = caches.default;
    const cacheKey = new Request(url.origin + url.pathname, request);
    if (!isPrivate) {
      const cached = await cache.match(cacheKey);
      if (cached) return cached;
    }

    const object = await env.ASSETS.get(key, { range: request.headers, onlyIf: request.headers });
    if (object === null) return new Response('Not Found', { status: 404, headers: corsHeaders(env) });

    const ext = key.split('.').pop().toLowerCase();
    const headers = new Headers(corsHeaders(env));
    object.writeHttpMetadata(headers);
    headers.set('Content-Type', TYPES[ext] || 'application/octet-stream');
    headers.set('ETag', object.httpEtag);
    headers.set(
      'Cache-Control',
      isPrivate ? 'private, max-age=3600'
        : key.endsWith('/packs.json') ? 'public, max-age=300'
        : 'public, max-age=31536000, immutable',
    );
    headers.set('X-Content-Type-Options', 'nosniff');

    if (!('body' in object) || !object.body) {
      return new Response(null, { status: 304, headers });
    }
    // R2 fills object.range even for whole-object reads; only answer 206 when a Range was asked for.
    const partial = request.headers.has('Range') && object.range && 'offset' in object.range;
    if (partial) {
      const start = object.range.offset;
      const end = start + object.range.length - 1;
      headers.set('Content-Range', `bytes ${start}-${end}/${object.size}`);
    }
    headers.set('Accept-Ranges', 'bytes');
    const status = partial ? 206 : 200;
    const response = new Response(request.method === 'HEAD' ? null : object.body, { status, headers });
    if (status === 200 && request.method === 'GET' && !isPrivate) ctx.waitUntil(cache.put(cacheKey, response.clone()));
    return response;
  },
};
