import { requirePageAdmin } from '@/lib/auth';
import { getContacts } from '@/lib/repositories/contactRepository';
import { DataTable } from '@/components/admin/DataTable';

export default async function ContactsPage() {
  await requirePageAdmin('dashboard:read');
  const contacts = await getContacts();

  return (
    <main>
      <h1>Contact Management</h1>
      <DataTable
        rows={contacts}
        empty="No contacts found."
        columns={[
          { key: 'owner', header: 'Owner', render: (r: any) => r.ownerUserId || '-' },
          { key: 'name',  header: 'Name',  render: (r: any) => r.name        || '-' },
          { key: 'phone', header: 'Phone', render: (r: any) => r.phone       || '-' },
        ]}
      />
    </main>
  );
}
