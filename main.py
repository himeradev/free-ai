import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import JSONResponse
import llmf

api = FastAPI()

@api.get("/ai")
async def ai_api(request: str):
    try:
        response = await run_in_threadpool(llmf.chat, request)
        text = str(response)
        model = getattr(response, "source", "unknown")

        return JSONResponse(
            content={"response": text, "model": model},
            media_type="application/json; charset=utf-8"
        )
    except Exception as e:
        raise HTTPException(500, str(e))

if __name__ == "__main__":
    uvicorn.run("main:api", host="0.0.0.0", port=11996)