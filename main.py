import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import JSONResponse
import llmf

api = FastAPI()

MODELS = {
    "qwen-coder": ("freeai", "qwen-coder"),
    "gpt-4o":     ("freeai", "gpt-4o"),
    "luna":       ("chatai", "gpt-5.6-luna"),
}

@api.get("/ai")
async def ai_api(request: str, model: str):
    try:
        cfg = MODELS.get(model)
        if cfg is None:
            raise HTTPException(400, f"Unknown model: {model}")

        provider, real_model = cfg
        response = await run_in_threadpool(
            llmf.chat, request, provider=provider, model=real_model
        )
        text = str(response)

        return JSONResponse(
            content={"response": text, "model": model},
            media_type="application/json; charset=utf-8",
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, str(e))


if __name__ == "__main__":
    uvicorn.run("main:api", host="0.0.0.0", port=11996)