import { requirePageAdmin } from '@/lib/auth';
import { NotificationBroadcastForm } from '@/components/admin/NotificationBroadcastForm';

export default async function NotificationsPage() {
  await requirePageAdmin('dashboard:read');

  return (
    <main>
      <h1>Notification Broadcasts</h1>
      <NotificationBroadcastForm />
    </main>
  );
}
