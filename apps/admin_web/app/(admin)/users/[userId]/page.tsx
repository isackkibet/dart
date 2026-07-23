import { requirePageAdmin } from '@/lib/auth';
import { getUserProfile } from '@/lib/repositories/userAdminRepository';

export default async function UserProfilePage({
  params,
}: {
  params: Promise<{ userId: string }>;
}) {
  await requirePageAdmin('dashboard:read');
  const { userId } = await params;
  const user = await getUserProfile(userId);

  return (
    <main>
      <h1>User Profile Detail</h1>
      <section className="card">
        <pre style={{ fontSize: 12, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
          {JSON.stringify(user, null, 2)}
        </pre>
      </section>
    </main>
  );
}
