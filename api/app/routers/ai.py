from uuid import UUID

from fastapi import APIRouter, Depends
from openai import AsyncOpenAI
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.deps import get_current_business
from app.models import AiConversation, Business
from app.schemas import AiChatRequest, AiChatResponse
from app.services.ai_service import chat_with_ai

router = APIRouter(prefix="/ai", tags=["ai"])


@router.get("/suggestions")
async def ai_suggestions():
    return {
        "suggestions": [
            "Combien j'ai facturé ce mois ?",
            "Factures impayées ?",
            "Stock faible ?",
            "Qui dois-je relancer ?",
        ]
    }


@router.post("/chat", response_model=AiChatResponse)
async def ai_chat(
    body: AiChatRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    openai_client = None
    if settings.openai_api_key:
        openai_client = AsyncOpenAI(api_key=settings.openai_api_key)

    conversation, response, intent, suggestions, action = await chat_with_ai(
        db, business, body.message, body.conversation_id, openai_client
    )

    return AiChatResponse(
        conversation_id=conversation.id,
        message=response,
        intent=intent,
        suggestions=suggestions,
        action=action,
    )


@router.get("/conversations")
async def list_conversations(
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AiConversation)
        .where(AiConversation.business_id == business.id)
        .order_by(AiConversation.updated_at.desc())
        .limit(20)
    )
    return [{"id": str(c.id), "created_at": c.created_at} for c in result.scalars().all()]
