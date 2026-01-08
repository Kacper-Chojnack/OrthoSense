import logging

import numpy as np

from app.ai.core.diagnostics import MovementDiagnostician

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def test_detect_knee_valgus():
    diag = MovementDiagnostician()

    mock_frame = [np.zeros(3)] * 33
    mock_frame[diag.MP["LEFT_KNEE"]] = [0.45, 0.5, 0.0]
    mock_frame[diag.MP["RIGHT_KNEE"]] = [0.55, 0.5, 0.0]
    mock_frame[diag.MP["LEFT_ANKLE"]] = [0.40, 0.8, 0.0]
    mock_frame[diag.MP["RIGHT_ANKLE"]] = [0.60, 0.8, 0.0]

    is_correct, errors = diag._analyze_squat([mock_frame])

    assert is_correct is False
    assert "Knee Valgus (Collapse)" in errors

    logging.info(f"Detected errors: {errors}")
