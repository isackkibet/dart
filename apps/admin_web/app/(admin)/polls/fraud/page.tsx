import { requirePageAdmin } from '@/lib/auth';
import { getHeldPollVotes } from '@/lib/repositories/pollsRepository';
import { DataTable } from '@/components/admin/DataTable';
import { PollVoteActions } from '@/components/admin/PollVoteActions';

export default async function PollFraudPage() {
  await requirePageAdmin('polls:write');
  const votes = await getHeldPollVotes();

  return (
    <main>
      <h1>Poll Fraud Vote Review</h1>
      <DataTable
        rows={votes}
        empty="No held poll votes found."
        columns={[
          { key: 'pollId', header: 'Poll', render: (row: any) => row.pollId || '-' },
          { key: 'userId', header: 'User', render: (row: any) => row.userId || '-' },
          { key: 'risk', header: 'Risk', render: (row: any) => row.riskReason || '-' },
          { key: 'actions', header: 'Actions', render: (row: any) => <PollVoteActions voteId={row.id} /> },
        ]}
      />
    </main>
  );
}
