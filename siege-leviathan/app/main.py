import os
import asyncio
from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.api.routes import router
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Check for existence of the certificate bundle before starting.
    """
    print(f"checking for certificate at {settings.CERT_BUNDLE}")
    # wait to handle the sidecare race condition
    while not os.path.exists(settings.CERT_BUNDLE):
        print("waiting ...")
        await asyncio.sleep(1)
    print("certificate found!")
    print("application starting")
    yield

app = FastAPI(lifespan=lifespan)

# include the router from the api module.
app.include_router(router)
