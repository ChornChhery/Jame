def test_profile_requires_authenticated_session(client):
    response = client.get("/api/v1/profile")

    assert response.status_code == 401
