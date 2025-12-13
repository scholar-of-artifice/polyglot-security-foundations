import ssl
import httpx
from fastapi import FastAPI

app = FastAPI()

# define where the Vault agent will place the certs
BUNDLE_CERT = "/app/certs/siege-leviathan.pem"


@app.get("/")
async def root():
    """
    This endpoint triggers the interaction.
    It acts as a Client to the 'overwhelming-minotaur' service.
    """
    # create a secture SLL context
    ssl_context = ssl.create_default_context(
        purpose=ssl.Purpose.SERVER_AUTH,
        cafile=BUNDLE_CERT
    )
    # load the client certificate and private key to prove OUR identity
    ssl_context.load_cert_chain(
        certfile=BUNDLE_CERT
        # keyfile is not needed if the private key is in the certfile
    )
    # define the tart service URL
    # NOTE: this comes from the docker-compose
    target_url = "https://overwhelming-minotaur:9000"
    # send the message defined as an example
    message = "I sent you a secret message *giggle*"
    print(f"Attempting to contact {target_url}...")
    try:
        # use httpx with the custom SSL context
        async with httpx.AsyncClient(verify=ssl_context) as client:
            response = await client.post(target_url, content=message)
            # return the conversation log
            return {
                "siege_leviathan_says": message,
                "overwhelming_minotaur_responds": response.text
            }
    except Exception as e:
        return {
            "error": f"Failed to connect to Minotaur: {str(e)}"
        }
