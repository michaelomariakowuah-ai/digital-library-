module.exports = async function handler(req, res) {
  const U = process.env.SUPABASE_URL, K = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!U || !K) return res.status(500).json({ error: 'Not set up yet: add SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the Vercel project settings, then redeploy.' });
  if (req.method !== 'POST') return res.status(405).json({ error: 'Use POST.' });
  try {
    const token = (req.headers.authorization || '').replace('Bearer ', '');
    const meRes = await fetch(U + '/auth/v1/user', { headers: { apikey: K, Authorization: 'Bearer ' + token } });
    const me = meRes.ok ? await meRes.json() : null;
    if (!me || !me.app_metadata || me.app_metadata.role !== 'admin') return res.status(403).json({ error: 'Administrators only.' });
    const H = { apikey: K, Authorization: 'Bearer ' + K, 'Content-Type': 'application/json' };
    const b = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : (req.body || {});
    const send = async (path, method, body) => {
      const r = await fetch(U + '/auth/v1/admin/users' + path, { method, headers: H, body: body ? JSON.stringify(body) : undefined });
      const j = await r.json().catch(() => ({}));
      if (!r.ok) throw new Error(j.msg || j.message || j.error_description || 'Request failed');
      return j;
    };
    const roles = ['admin', 'monitor'];
    if (b.action === 'list') {
      const j = await send('?per_page=200', 'GET');
      return res.status(200).json({ users: (j.users || []).map(u => ({ id: u.id, email: u.email, role: (u.app_metadata && u.app_metadata.role) || '' })) });
    }
    if (b.action === 'create') {
      if (!b.email || !b.password || b.password.length < 8 || !roles.includes(b.role)) return res.status(400).json({ error: 'Enter an email, a password of 8+ characters and a role.' });
      await send('', 'POST', { email: b.email, password: b.password, email_confirm: true, app_metadata: { role: b.role } });
      return res.status(200).json({ ok: true });
    }
    if (!b.id) return res.status(400).json({ error: 'Missing person.' });
    if (b.id === me.id && (b.action === 'role' || b.action === 'delete')) return res.status(400).json({ error: 'You cannot change or remove your own account.' });
    if (b.action === 'role') {
      if (!roles.includes(b.role)) return res.status(400).json({ error: 'Invalid role.' });
      await send('/' + b.id, 'PUT', { app_metadata: { role: b.role } });
    } else if (b.action === 'password') {
      if (!b.password || b.password.length < 8) return res.status(400).json({ error: 'Password must be 8+ characters.' });
      await send('/' + b.id, 'PUT', { password: b.password });
    } else if (b.action === 'delete') {
      await send('/' + b.id, 'DELETE');
    } else return res.status(400).json({ error: 'Unknown action.' });
    return res.status(200).json({ ok: true });
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Something went wrong.' });
  }
};
