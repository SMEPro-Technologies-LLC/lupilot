/**
 * IOS+ API Gateway
 * Routes requests to backend services, enforces auth, rate limiting
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { createProxyMiddleware } = require('http-proxy-middleware');
const Redis = require('ioredis');

const app = express();
const PORT = process.env.PORT || 3000;
const EDU_REPORTER_API_URL = process.env.EDU_REPORTER_API_URL || 'http://localhost:8080';
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379/1';
const JWT_SECRET = process.env.JWT_SECRET || 'local-dev-secret';

const redis = new Redis(REDIS_URL);

app.use(helmet());
app.use(cors());
app.use(express.json());

const limiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip,
  handler: (req, res) => {
    res.status(429).json({ error: 'Too many requests', retryAfter: 60 });
  }
});
app.use(limiter);

app.get('/v1/health/live', (req, res) => {
  res.status(200).json({ status: 'alive', timestamp: new Date().toISOString() });
});

app.get('/v1/health/ready', async (req, res) => {
  try {
    await redis.ping();
    res.status(200).json({
      status: 'ready',
      services: { redis: 'up', api: 'up' },
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(503).json({
      status: 'not_ready',
      services: { redis: 'down', api: 'up' },
      error: err.message
    });
  }
});

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    req.user = { role: 'advisor', tier: 2, syn_id: 'DEMO-ADVISOR-001' };
    return next();
  }
  req.user = { role: 'advisor', tier: 2, syn_id: 'DEMO-ADVISOR-001' };
  next();
};

const eduReporterProxy = createProxyMiddleware({
  target: EDU_REPORTER_API_URL,
  changeOrigin: true,
  pathRewrite: { '^/v1/edu-reporter': '/v1' },
  onProxyReq: (proxyReq, req, res) => {
    proxyReq.setHeader('X-User-Role', req.user?.role || 'anonymous');
    proxyReq.setHeader('X-User-Syn-ID', req.user?.syn_id || 'anonymous');
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err.message);
    res.status(502).json({ error: 'Backend service unavailable', detail: err.message });
  }
});

app.use('/v1/edu-reporter', authMiddleware, eduReporterProxy);

app.get('/v1/uc/:objective', authMiddleware, async (req, res) => {
  const { objective } = req.params;
  const validUCs = ['uc-01', 'uc-02', 'uc-03', 'uc-04', 'uc-05'];
  if (!validUCs.includes(objective.toLowerCase())) {
    return res.status(400).json({ error: 'Invalid UC objective', valid: validUCs });
  }
  try {
    const response = await fetch(`${EDU_REPORTER_API_URL}/v1/${objective.toLowerCase()}`, {
      headers: { 
        'Content-Type': 'application/json',
        'X-User-Role': req.user.role,
        'X-User-Syn-ID': req.user.syn_id
      }
    });
    const data = await response.json();
    res.status(response.status).json(data);
  } catch (err) {
    res.status(502).json({ error: 'Edu Reporter API unavailable', detail: err.message });
  }
});

app.get('/', (req, res) => {
  res.json({
    service: 'IOS+ API Gateway',
    version: '1.0.0-mvp',
    status: 'running',
    endpoints: [
      '/v1/health/live',
      '/v1/health/ready',
      '/v1/edu-reporter/*',
      '/v1/uc/uc-01',
      '/v1/uc/uc-02',
      '/v1/uc/uc-03',
      '/v1/uc/uc-04',
      '/v1/uc/uc-05'
    ]
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error', requestId: req.id });
});

app.listen(PORT, () => {
  console.log(`API Gateway listening on port ${PORT}`);
  console.log(`Edu Reporter API: ${EDU_REPORTER_API_URL}`);
  console.log(`Redis: ${REDIS_URL}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  redis.disconnect();
  process.exit(0);
});
