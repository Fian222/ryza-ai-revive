/* Fish Audio request, clone lifecycle, error, and proxy regressions.
   Run: node scripts/fish_audio_regression.js */
'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const WEB = path.join(ROOT, 'web');
let failures = 0;
const bad = (msg) => { failures++; console.log('  FAIL ' + msg); };
const ok = (cond, msg) => { if (cond) console.log('  PASS ' + msg); else bad(msg); };

const requests = [];
const replies = [];
const timingEvents = [];
let blobNumber = 0;

class FakeXHR {
  constructor() {
    this.headers = {};
    this.responseType = '';
    this.status = 0;
  }
  open(method, url) { this.method = method; this.url = url; }
  setRequestHeader(name, value) { this.headers[name.toLowerCase()] = String(value); }
  getResponseHeader(name) {
    return String(name).toLowerCase() === 'content-type' ? (this.contentType || '') : '';
  }
  send(body) {
    requests.push({ method: this.method, url: this.url, headers: this.headers, body });
    const reply = replies.shift() || { status: 200, audio: true };
    this.status = reply.status;
    this.contentType = reply.contentType || (reply.audio ? 'audio/mpeg' : 'application/json');
    if (this.responseType === 'arraybuffer') {
      const bytes = reply.audio
        ? Uint8Array.from([0x49, 0x44, 0x33, 0x04])
        : new TextEncoder().encode(reply.raw || JSON.stringify(reply.json || {}));
      this.response = bytes.buffer;
    } else {
      this.responseText = reply.raw || JSON.stringify(reply.json || {});
    }
    queueMicrotask(() => reply.network ? this.onerror() : this.onload());
  }
}

function TestURL(value, base) { return new URL(value, base); }
TestURL.createObjectURL = function () { return 'blob:fish-test-' + (++blobNumber); };
TestURL.revokeObjectURL = function () {};

const store = {};
const sandbox = {
  console, Math, JSON, String, Array, RegExp, Object, Date, Number,
  isFinite, parseInt, parseFloat, Infinity, NaN, Set, Map, Promise,
  Blob, FormData, TextDecoder, TextEncoder, Uint8Array, ArrayBuffer,
  atob, btoa, queueMicrotask,
  XMLHttpRequest: FakeXHR,
  URL: TestURL,
  location: { origin: 'http://127.0.0.1:8765' },
  document: { getElementById() { return null; } },
  localStorage: {
    getItem(k) { return k in store ? store[k] : null; },
    setItem(k, v) { store[k] = String(v); },
    removeItem(k) { delete store[k]; },
    key(i) { return Object.keys(store)[i] || null; },
    get length() { return Object.keys(store).length; }
  },
  fetch: async function (url) {
    const isReference = /prologue_08\.wav$/.test(String(url));
    return {
      ok: isReference,
      blob: async function () { return new Blob(['reference audio'], { type: 'audio/wav' }); }
    };
  }
};
sandbox.window = sandbox;
sandbox.globalThis = sandbox;
sandbox.App = {
  _ttsTimingMark(name, meta) { timingEvents.push({ name, meta }); }
};
vm.createContext(sandbox);
for (const file of ['config.js', 'api.js']) {
  vm.runInContext(fs.readFileSync(path.join(WEB, 'js', file), 'utf8'), sandbox, { filename: file });
}

const A = sandbox.Api;
const C = sandbox.Config;
const tts = C.section('tts');
const fishToken = ['test', 'token'].join('-');
tts.provider = 'fish';
tts.mode = 'clone';
tts.fishBaseUrl = '';
tts.fishApiKey = fishToken;
tts.fishModel = 's2.1-pro-free';
tts.fishVoice = 'saved-reference';

function targetOf(proxyUrl) {
  return new URL(proxyUrl, 'http://127.0.0.1:8765').searchParams.get('u');
}

async function run() {
  const originalClone = A.fishCloneVoice;
  let cloneCalls = 0;
  A.fishCloneVoice = function () { cloneCalls++; return Promise.resolve('unexpected-clone'); };

  replies.push({ status: 200, audio: true });
  const audioUrl = await A.speak('こんにちは。', 'ja', 'chat', {
    generation: 1, chunk: 0, chars: 7
  });
  const first = requests.shift();
  const body = JSON.parse(first.body);
  ok(targetOf(first.url) === 'https://api.fish.audio/v1/tts',
     'Fish synthesis uses POST https://api.fish.audio/v1/tts through /_proxy');
  ok(first.method === 'POST', 'Fish synthesis uses POST');
  ok(first.headers.authorization === 'Bearer ' + fishToken,
     'Fish Authorization uses a Bearer token');
  ok(first.headers['content-type'] === 'application/json',
     'Fish synthesis sends JSON');
  ok(first.headers.model === 's2.1-pro-free',
     'Fish model is sent as the model header');
  ok(!('api-key' in first.headers), 'Fish key is not duplicated into an api-key header');
  ok(body.text === 'こんにちは。' && body.format === 'mp3',
     'Fish JSON contains spoken text and mp3 format');
  ok(body.reference_id === 'saved-reference' && !body.voiceId && !body.modelId,
     'saved Fish reference_id is sent without retired body fields');
  ok(/^blob:fish-test-/.test(audioUrl), 'binary MP3 response becomes a Blob URL');
  ok(timingEvents.map((x) => x.name).join('|') ===
     'fish_request_start|fish_response_first_byte|fish_response_complete',
     'Fish timing records request, observable first byte, and completion without headers');
  ok(cloneCalls === 0, 'stored reference_id is reused without cloning');

  timingEvents.length = 0;
  const llm = C.section('llm');
  llm.apiKey = ['llm', 'test', 'token'].join('-');
  llm.baseUrl = 'https://llm.example/v1';
  llm.model = 'test-model';
  replies.push({ status: 200, json: { choices: [{ message: { content: '返事。' } }] } });
  await A.chat([], 'hello', { speechGeneration: 7, mode: 'chat', style: 'voice' });
  requests.shift();
  ok(timingEvents.map((x) => x.name).join('|') === 'llm_request_start|llm_response_start',
     'LLM timing distinguishes request dispatch from first observable response data');

  replies.push({ status: 200, audio: true });
  await A.speak('もう一度。', 'ja', 'chat');
  requests.shift();
  ok(cloneCalls === 0, 'cloning is not repeated for later TTS messages');

  tts.fishVoice = '';
  A.fishCloneVoice = function () { cloneCalls++; return Promise.resolve('new-reference'); };
  replies.push({ status: 200, audio: true }, { status: 200, audio: true });
  await A.speak('最初。', 'ja', 'chat');
  await A.speak('次。', 'ja', 'chat');
  requests.splice(0, 2);
  ok(cloneCalls === 1 && tts.fishVoice === 'new-reference',
     'missing reference is cloned once, persisted, and reused');

  A.fishCloneVoice = function () { cloneCalls++; return Promise.resolve(''); };
  tts.fishVoice = '';
  let invalid = '';
  try { await A.speak('invalid', 'ja', 'chat'); } catch (e) { invalid = e.message; }
  ok(/invalid or missing reference_id/.test(invalid),
     'empty clone result reports invalid/missing reference_id');

  A.fishCloneVoice = originalClone;
  replies.push({ status: 201, json: { _id: 'created-reference' } });
  const created = await A.fishCloneVoice();
  const clone = requests.shift();
  const cloneFields = Array.from(clone.body.entries());
  ok(targetOf(clone.url) === 'https://api.fish.audio/model' && created === 'created-reference',
     'voice clone uses /model and persists its returned _id as reference_id');
  ok(cloneFields.some(([k, v]) => k === 'type' && v === 'tts') &&
     cloneFields.some(([k, v]) => k === 'train_mode' && v === 'fast') &&
     cloneFields.some(([k]) => k === 'voices'),
     'voice clone sends the current multipart model fields');

  const secret = ['redaction', 'sentinel'].join('-');
  ok(/invalid or missing API key/.test(A._fishErrorMessage(401, '', secret, 'tts')),
     'Fish 401 maps to invalid/missing API key');
  ok(/permission, model, or reference access denied/.test(A._fishErrorMessage(403, '', secret, 'tts')),
     'Fish 403 maps to permission/model/reference access');
  ok(/rate limit or quota exceeded/.test(A._fishErrorMessage(429, '', secret, 'tts')),
     'Fish 429 maps to rate limit/quota');
  const safe = A._fishErrorMessage(500, JSON.stringify({ message: 'failed ' + secret }), secret, 'tts');
  ok(!safe.includes(secret) && safe.includes('[redacted]'), 'Fish errors redact the API key');

  tts.provider = 'fish';
  tts.fishVoice = 'keep-this-reference';
  replies.push({ status: 500, json: { message: 'clone failed' } });
  let cloneFailure = '';
  try { await A.fishCloneVoice(); } catch (e) { cloneFailure = e.message; }
  requests.shift();
  ok(/voice clone\/reference creation failed/.test(cloneFailure) &&
     tts.fishVoice === 'keep-this-reference',
     'clone failure is identified without destroying a saved reference_id');

  replies.push({ status: 0, network: true });
  let networkFailure = '';
  try { await A.speak('network', 'en', 'chat'); } catch (e) { networkFailure = e.message; }
  requests.shift();
  ok(/network\/proxy failure/.test(networkFailure), 'Fish network/proxy failures are identified');

  tts.provider = 'openai';
  tts.mode = 'preset';
  tts.baseUrl = 'https://tts.example/v1';
  tts.apiKey = 'other-provider-key';
  tts.modelPreset = 'other-model';
  replies.push({ status: 200, json: { choices: [{ message: { audio: { data: 'SUQzBA==' } } }] } });
  await A.speak('other provider', 'en', 'chat');
  const other = requests.shift();
  ok(targetOf(other.url) === 'https://tts.example/v1/chat/completions' && !other.headers.model,
     'non-Fish TTS retains its existing request path and headers');

  const sources = [
    fs.readFileSync(path.join(ROOT, 'scripts', 'serve.py'), 'utf8'),
    fs.readFileSync(path.join(ROOT, 'desktop', 'main.js'), 'utf8'),
    fs.readFileSync(path.join(ROOT, 'android', 'app', 'src', 'main', 'java',
                              'com', 'ryza', 'chat', 'AssetServer.java'), 'utf8')
  ];
  ok(sources.every((src) => /["']model["']|\"model\"/.test(src)),
     'browser, desktop, and Android proxies forward the Fish model header');
}

run().then(function () {
  console.log(failures ? '\nFISH AUDIO: ' + failures + ' FAILURES' : '\nFISH AUDIO: ALL PASS');
  process.exit(failures ? 1 : 0);
}).catch(function (err) {
  console.error('  FAIL unexpected error:', err && err.stack || err);
  process.exit(1);
});
