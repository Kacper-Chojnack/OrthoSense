"""Report generation utilities.

Movement diagnostics are performed client-side (Edge AI) for privacy.
This module only provides text report formatting for any future server-side needs.
"""

MOVEMENT_CORRECT = "Movement correct."


class ReportGenerator:
    """Generates text reports from diagnostic results."""

    def generate_report(self, analysis_tuple, exercise_name):
        if not analysis_tuple:
            return "No result."

        is_ok, feedback = analysis_tuple

        lines = [f"Exercise: {exercise_name}"]

        if is_ok:
            lines.append(f"Status: {MOVEMENT_CORRECT}")
            lines.append("Good form - keep it up!")
        else:
            lines.append("Status: Needs improvement\n")
            lines.append("Issues:")

            if isinstance(feedback, dict):
                for err, detail in feedback.items():
                    if detail is True:
                        lines.append(f"  - {err}")
                    else:
                        lines.append(f"  - {err}: {detail}")

            elif isinstance(feedback, str):
                lines.append(f"  - {feedback}")

            lines.append("\nTip: Slow down and focus on form.")

        return "\n".join(lines)
