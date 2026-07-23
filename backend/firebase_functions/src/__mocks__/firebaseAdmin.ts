// Shared Firestore mock for unit tests.
// Tests that need specific query results should override mockGet / mockCollection.

export const mockSet = jest.fn().mockResolvedValue(undefined);
export const mockAdd = jest.fn().mockResolvedValue({ id: 'mock-doc-id' });
export const mockGet = jest.fn().mockResolvedValue({ docs: [], exists: false });
export const mockUpdate = jest.fn().mockResolvedValue(undefined);
export const mockDelete = jest.fn().mockResolvedValue(undefined);

export const mockDoc = jest.fn(() => ({
  get: mockGet,
  set: mockSet,
  update: mockUpdate,
  delete: mockDelete,
  id: 'mock-doc-id',
}));

export const mockWhere = jest.fn().mockReturnThis();

export const mockCollection = jest.fn(() => ({
  doc: mockDoc,
  add: mockAdd,
  where: mockWhere,
  get: mockGet,
}));

export const mockRunTransaction = jest.fn(async (fn: (tx: object) => Promise<void>) => {
  const tx = {
    get: mockGet,
    set: mockSet,
    update: mockUpdate,
    delete: mockDelete,
  };
  await fn(tx);
});

export const db = {
  collection: mockCollection,
  runTransaction: mockRunTransaction,
};

export const FieldValue = {
  serverTimestamp: () => ({ _type: 'serverTimestamp' }),
  increment: (n: number) => ({ _type: 'increment', n }),
};
