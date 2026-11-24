# Free ai local api

# Установка

```bash
pip install fastapi uvicorn
```

Модуль llmf должен лежать рядом с main.py.

# Запуск

```bash
python main.py
```

Сервер: http://0.0.0.0:11996

# Эндпоинт

GET /ai?request=<текст>&model=<модель>

Модели: qwen-coder, gpt-4o, luna

# Ответ:

```json
{"response": "...", "model": "gpt-4o"}
```

Ошибки: 400 — неизвестная модель, 500 — ошибка LLM.

# Пример

```bash
curl "http://localhost:11996/ai?request=Привет&model=gpt-4o"
```

```python
import requests
print(requests.get("http://localhost:11996/ai",
      params={"request": "Привет", "model": "luna"})
