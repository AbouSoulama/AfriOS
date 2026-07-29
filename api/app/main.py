from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db
from app.routers import ai, auth, business, clients, dashboard, invoices, jobs, payments, products, reminders, sync


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

prefix = settings.api_prefix

app.include_router(auth.router, prefix=prefix)
app.include_router(business.router, prefix=prefix)
app.include_router(clients.router, prefix=prefix)
app.include_router(products.router, prefix=prefix)
app.include_router(invoices.router, prefix=prefix)
app.include_router(payments.router, prefix=prefix)
app.include_router(dashboard.router, prefix=prefix)
app.include_router(ai.router, prefix=prefix)
app.include_router(reminders.router, prefix=prefix)
app.include_router(sync.router, prefix=prefix)
app.include_router(jobs.router, prefix=prefix)


@app.get("/health")
async def health():
    return {"status": "ok", "app": settings.app_name, "version": settings.app_version}
