'use client';
import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { initializeApp, getApps } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY!,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN!,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID!,
};

if (!getApps().length) {
  initializeApp(firebaseConfig);
}

export default function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = searchParams.get('next') || '/dashboard';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: React.SyntheticEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError('');
    try {
      const auth = getAuth();
      const credential = await signInWithEmailAndPassword(auth, email, password);
      const idToken = await credential.user.getIdToken();
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken }),
      });
      const body = await response.json();
      if (!response.ok) {
        throw new Error(body.error || 'Login failed');
      }
      router.replace(next);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setBusy(false);
    }
  }

  return (
    <main
      style={{
        minHeight: '100vh',
        display: 'grid',
        placeItems: 'center',
        padding: 24,
      }}
    >
      <form
        onSubmit={submit}
        className="card"
        style={{ width: '100%', maxWidth: 460 }}
      >
        <span className="badge">Admin Auth</span>
        <h1>YohPal Admin Login</h1>
        <input
          placeholder="Email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          style={{ width: '100%', marginTop: 16, padding: 12, borderRadius: 12 }}
        />
        <input
          placeholder="Password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          style={{ width: '100%', marginTop: 12, padding: 12, borderRadius: 12 }}
        />
        {error ? (
          <p style={{ color: 'var(--danger)', marginTop: 8, fontSize: 14 }}>{error}</p>
        ) : null}
        <button
          className="btn"
          type="submit"
          disabled={busy}
          style={{ width: '100%', marginTop: 16, opacity: busy ? 0.7 : 1 }}
        >
          {busy ? 'Signing in...' : 'Login'}
        </button>
      </form>
    </main>
  );
}
