from fastapi import FastAPI
from app.api.routes import router

app = FastAPI()

# include the router from the api module.
app.include_router(router)
