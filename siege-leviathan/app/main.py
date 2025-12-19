import os
import ssl
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
    while True:
        # check if file exists first
        if os.path.exists(settings.CERT_BUNDLE):
            try:
                # attempt to load the file as a cert chain
                context = ssl.create_default_context()
                context.load_cert_chain(settings.CERT_BUNDLE)
                print("certificate found and valid!")
                break
            except (ssl.SSLError, OSError):
                # the file exists but is not yet valid
                pass
        print("waiting ...")
        await asyncio.sleep(1)

    print("application starting")
    yield

app = FastAPI(lifespan=lifespan)

# include the router from the api module.
app.include_router(router)
