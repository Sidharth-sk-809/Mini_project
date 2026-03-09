const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

function getAdminUser() {
  try {
    const raw = localStorage.getItem('admin_user');
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export async function logAdminAction({ action, entityType, entityId = null, payload = {} }) {
  const user = getAdminUser();
  const adminUserId = user?.user_id ?? user?.id;

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !adminUserId) {
    return;
  }

  try {
    await fetch(`${SUPABASE_URL}/rest/v1/admin_audit_logs`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({
        admin_user_id: adminUserId,
        action,
        entity_type: entityType,
        entity_id: entityId,
        payload,
      }),
    });
  } catch (error) {
    console.warn('Audit log failed', error);
  }
}
