import time
from app.ai.core.engine import OrthoSensePredictor
import numpy as np
import asyncio

async def test_inference_latency():
    engine = OrthoSensePredictor()
    dummy_input = np.random.rand(60, 33, 3).astype(np.float32) 

    async def predict():
        return engine.analyze(dummy_input)

    times = []
    for _ in range(100):
        start = time.time()
        await predict()
        end = time.time()
        times.append((end - start) * 1000) # ms

    avg_time = sum(times) / len(times)
    print(f"\nŚrednia latencja: {avg_time:.2f}ms")

    assert avg_time < 100, f"To slow! It's {avg_time}ms, supposed to be <100ms"
