import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from firestore_client import _build_queued_jobs_query


class FakeQuery:
    def __init__(self):
        self.where_called = False
        self.limit_called = False

    def where(self, *args, **kwargs):
        self.where_called = True
        return self

    def order_by(self, *args, **kwargs):
        raise AssertionError("order_by should not be used for queued-job polling")

    def limit(self, *args, **kwargs):
        self.limit_called = True
        return self


class FakeCollection:
    def __init__(self):
        self.query = FakeQuery()

    def where(self, *args, **kwargs):
        return self.query.where(*args, **kwargs)


class FakeDb:
    def __init__(self):
        self.collection_name = None
        self.collection_obj = FakeCollection()

    def collection(self, name):
        self.collection_name = name
        return self.collection_obj


def test_build_queued_jobs_query_uses_simple_status_filter_without_order_by():
    db = FakeDb()

    query = _build_queued_jobs_query(db, limit=3)

    assert db.collection_name == "mediaJobs"
    assert query is not None
    assert query.where_called is True
    assert query.limit_called is True
