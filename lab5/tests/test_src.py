from fastapi.testclient import TestClient
from src import __version__
from src.main import app

client = TestClient(app)


def test_version():
    assert __version__ == "0.1.0"


def test_root():
    response = client.get("/")
    assert response.status_code == 404


def test_hello_no_param():
    response = client.get("/hello")
    assert response.status_code == 422


def test_hello_no_name():
    response = client.get("/hello?name=")
    assert response.status_code == 422


def test_hello_name():
    response = client.get("/hello?name=jordan")
    assert response.status_code == 200
    assert response.json() == "hello jordan"


def test_hello_bad_param():
    response = client.get("/hello?first=jordan")
    assert response.status_code == 422


def test_docs():
    response = client.get("/docs")
    assert response.status_code == 200


def test_json():
    response = client.get("/openapi.json")
    assert response.status_code == 200


def test_predict():
    response = client.post("/predict")
    assert response.status_code == 422


def test_valid_prediction():
    response = client.post(
        "/predict",
        json=[
            {
                "MedInc": 1,
                "Population": 1,
                "AveOccup": 1,
                "HouseAge": 1,
                "AveRooms": 1,
                "Latitude": 1,
                "Longitude": 1,
                "AveBedrms": 1,
            }
        ],
    )
    assert response.status_code == 200
    assert response.json()["prediction"] == [1.9375488146891446]
    assert response.json() == {
        "query_key": "f697f017cf176e1f5679971307a30c0d",
        "inputs": [
            {
                "MedInc": 1.0,
                "HouseAge": 1.0,
                "AveRooms": 1.0,
                "AveBedrms": 1.0,
                "Population": 1.0,
                "AveOccup": 1.0,
                "Latitude": 1.0,
                "Longitude": 1.0,
            }
        ],
        "prediction": [1.9375488146891446],
    }


def test_invalid__dict_prediction():
    response = client.post(
        "/predict",
        json={
            "MedInc": 1,
            "Population": 1,
            "AveOccup": 1,
            "HouseAge": 1,
            "AveRooms": 1,
            "Latitude": 1,
            "Longitude": 1,
            "AveBedrms": 1,
        },
    )
    assert response.status_code == 422


def test_liz_input():
    response = client.post(
        "/predict",
        json=[
            {
                "HouseAge": 41,
                "MedInc": 8.32,
                "AveRooms": 6.98,
                "AveBedrms": 1.02,
                "Population": 322,
                "AveOccup": 2.5,
                "Latitude": 37.88,
                "Longitude": -122.21,
            }
        ],
    )
    assert response.status_code == 200
    assert response.json()["query_key"] == "76539e7e8faf8bad0269697e56f0e62c"
    assert response.json()["prediction"] == [4.414593298251905]


def test_long_list_of_inputs():
    response = client.post(
        "/predict",
        json=[
            {
                "MedInc": 1,
                "HouseAge": 1,
                "AveRooms": 1,
                "AveBedrms": 1,
                "Population": 1,
                "AveOccup": 1,
                "Latitude": 1,
                "Longitude": 1,
            },
            {
                "MedInc": 2,
                "HouseAge": 2,
                "AveRooms": 2,
                "AveBedrms": 2,
                "Population": 2,
                "AveOccup": 2,
                "Latitude": 90,
                "Longitude": 90,
            },
            {
                "MedInc": 5,
                "HouseAge": 5,
                "AveRooms": 5,
                "AveBedrms": 5,
                "Population": 5,
                "AveOccup": 5,
                "Latitude": 90,
                "Longitude": 90,
            },
            {
                "HouseAge": 41,
                "MedInc": 8.32,
                "AveRooms": 6.98,
                "AveBedrms": 1.02,
                "Population": 322,
                "AveOccup": 2.5,
                "Latitude": 37.88,
                "Longitude": -122.21,
            },
        ],
    )
    assert response.status_code == 200
    assert response.json()["query_key"] == "304eeac871f339bc0438fdd9b4cfff3e"
    assert response.json()["prediction"] == [
        1.9375488146891446,
        1.9375488146891446,
        1.9375488146891446,
        4.414593298251905,
    ]


def test_long_list_with_bad_inputs():
    response = client.post(
        "/predict",
        json=[
            {
                "MedInc": 1,
                "HouseAge": 1,
                "AveRooms": 1,
                "AveBedrms": 1,
                "Population": 1,
                "AveOccup": 1,
                "Latitude": 1,
                "Longitude": 1,
            },
            {
                "MedInc": 2,
                "HouseAge": 2,
                "AveRooms": 2,
                "AveBedrms": 2,
                "Population": 2,
                "AveOccup": 2,
                "Latitude": 90,
                "Longitude": 90,
            },
            {
                "MedInc": 5,
                "HouseAge": 5,
                "AveRooms": 5,
                "AveBedrms": -4,
                "Population": 5,
                "AveOccup": 5,
                "Latitude": 90,
                "Longitude": 90,
            },
            {
                "HouseAge": 41,
                "MedInc": 8.32,
                "AveRooms": 6.98,
                "AveBedrms": 1.02,
                "Population": 322,
                "AveOccup": 2.5,
                "Latitude": 37.88,
                "Longitude": -122.21,
            },
        ],
    )
    assert response.status_code == 422
