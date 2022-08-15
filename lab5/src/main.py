import joblib
import numpy as np
import os
import json
import hashlib

from fastapi import FastAPI, HTTPException, Request, Response
from fastapi_redis_cache import FastApiRedisCache, cache
from pydantic import BaseModel, validator, Extra


app = FastAPI()
LOCAL_REDIS_URL = "redis://redis:6379/0"
LOCAL_TEST_URL = "redis://localhost:6379/0"


@app.on_event("startup")
def startup():
    redis_cache = FastApiRedisCache()
    redis_cache.init(
        host_url=os.environ.get("REDIS_URL", LOCAL_REDIS_URL),
        prefix="myapi-cache",
        response_header="X-MyAPI-Cache",
        ignore_arg_types=[None],
    )


@app.get("/hello")
@cache()
def hello_response(name: str):
    if len(name) < 1:
        raise HTTPException(
            status_code=422, detail="Unprocessable Entity. No name provided."
        )
    try:
        return f"hello {name}"
    except NameError:
        raise HTTPException(
            status_code=422,
            detail="Unprocessable Entity. Invalid parameter(s) provided.",
        )


@app.get("/health")
def health_check():
    return {"status": "Online"}


features = clf = joblib.load("features.pkl")
model = joblib.load("model_pipeline.pkl")


class UserIn(BaseModel, extra=Extra.forbid):
    MedInc: float
    HouseAge: float
    AveRooms: float
    AveBedrms: float
    Population: float
    AveOccup: float
    Latitude: float
    Longitude: float

    @validator("MedInc")
    def MedInc_must_be_positive(cls, v):
        assert v >= 0, f"MedInc {v} is not a positive number."
        return v

    @validator("HouseAge")
    def HouseAge_must_be_positive(cls, v):
        assert v >= 0, f"HouseAge : {v} is not a positive number."
        return v

    @validator("AveRooms")
    def AveRooms_must_be_positive(cls, v):
        assert v >= 0, f"AveRooms : {v} is not a positive number."
        return v

    @validator("AveBedrms")
    def AveBedrms_must_be_positive(cls, v):
        assert v >= 0, f"AveBedrms : {v} is not a positive number."
        return v

    @validator("Population")
    def Population_must_be_positive(cls, v):
        assert v >= 0, f"Population : {v} is not a positive number."
        return v

    @validator("AveOccup")
    def AveOccup_must_be_positive(cls, v):
        assert v >= 0, f"AveOccup : {v} is not a positive number."
        return v

    @validator("Latitude")
    def param_Latitude_must_exist(cls, v):
        assert (
            -90 <= v <= 90
        ), f"Latitude : {v} must be greater than or equal to -90 and less than or equal to 90."
        return v

    @validator("Longitude")
    def Longitude_must_exist(cls, v):
        assert (
            -180.0 < v <= 180
        ), f"Longitude : {v} must be greater than -180 and less than or equal to 180."
        return v


class UserOut(BaseModel):
    query_key: str
    inputs: str
    prediction: list[float]

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)

    @validator("prediction")
    def output_is_numeric(cls, v):
        for i in v:
            assert i >= 0, f"Prediction: {i} should be positive. Someone call James."
        return v


@app.post("/predict", response_model=UserOut)
@cache()
async def predict_response(user_input: list[UserIn]):

    query_ = []
    for input_ in user_input:
        json_ = input_
        input_data = [
            [
                json_.MedInc,
                json_.HouseAge,
                json_.AveRooms,
                json_.AveBedrms,
                json_.Population,
                json_.AveOccup,
                json_.Latitude,
                json_.Longitude,
            ]
        ]
        query_.append(input_data)
    X = np.concatenate([np.array(i) for i in query_])
    output_ = list(model.predict(X))

    my_key = hashlib.md5(str(user_input).encode()).hexdigest()
    user_output_ = {
        "query_key": my_key,
        "inputs": str(user_input),
        "prediction": output_,
    }

    # user_out = UserOut.parse_obj(user_output_)
    return user_output_
