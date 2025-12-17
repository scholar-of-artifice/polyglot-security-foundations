from fastapi import APIRouter
from app.services.client import send_secret_message

router = APIRouter()


@router.get("/")
async def root():
    """
    This endpoint triggers the interaction.
    It acts as a Client to the 'overwhelming-minotaur' service.
    """
    # define the message
    message = "I sent you a secret message *giggle*"
    # call the isolated business logic
    result = await send_secret_message(message=message)
    # return the result
    return result
