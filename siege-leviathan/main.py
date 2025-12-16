import ssl
import httpx
import os
from fastapi import FastAPI

app = FastAPI()

# define where the Vault agent will place the certs
BUNDLE_CERT = os.environ.get(key="CERT_BUNDLE")
TARGET_URL = os.environ.get(key="TARGET_URL")


@app.get("/")
async def root():
    """
    This endpoint triggers the interaction.
    It acts as a Client to the 'overwhelming-minotaur' service.
    """
    # check that the environment variables load
    if not BUNDLE_CERT or not TARGET_URL:
        return {"error": "Configuration Error: CERT_BUNDLE or TARGET_URL is not set."}
    # create a secure SSL context
    ssl_context = ssl.create_default_context(
        purpose=ssl.Purpose.SERVER_AUTH,
        cafile=BUNDLE_CERT
    )
    # load the client certificate and private key to prove OUR identity
    ssl_context.load_cert_chain(
        certfile=BUNDLE_CERT
        # keyfile is not needed if the private key is in the certfile
    )
    # define the start service URL
    # NOTE: this comes from the docker-compose
    # send the message defined as an example
    message = "I sent you a secret message *giggle*"
    print(f"Attempting to contact {TARGET_URL}...")
    try:
        # use httpx with the custom SSL context
        async with httpx.AsyncClient(verify=ssl_context) as client:
            response = await client.post(TARGET_URL, content=message)
            # return the conversation log
            return {
                "siege_leviathan_says": message,
                "overwhelming_minotaur_responds": response.text
            }
    except Exception as e:
        return {
            "error": f"Failed to connect to overwhelming-minotaur: {str(e)}"
        }
