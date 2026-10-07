import pytest
from app.app import app

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client

def test_index(client):
    res = client.get("/")
    assert res.status_code == 200
    assert b"OrderHub API" in res.data

def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json() == {"status": "UP"}

def test_orders(client):
    res = client.get("/orders")
    assert res.status_code == 200
    assert len(res.get_json()) > 0